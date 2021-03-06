//
//  iGCSMavLinkInterface.m
//  iGCS
//
//  Created by Andrew Aarestad on 2/22/13.
//
//

#import "AppDelegate.h" // For TestFlight control

#import "MavLinkTools.h"
#import "DateTimeUtils.h"
#import "iGCSMavLinkInterface.h"

#import "CommsViewController.h"
#import "GCSMapViewController.h"
#import "WaypointsViewController.h"

#import "mavlink_helpers.h"

#import "GaugeViewCommon.h"

#import "Logger.h"

@implementation iGCSMavLinkInterface

@synthesize mavlinkTransactionProgressDialog;
@synthesize mavlinkRequestAttempts;

// TODO: Limit scope of these variables
iGCSMavLinkInterface *appMLI;
mavlink_message_t msg;
mavlink_status_t status;
mavlink_heartbeat_t heartbeat;

+(iGCSMavLinkInterface*)createWithViewController:(MainViewController*)mainVC
{
    iGCSMavLinkInterface *interface = [[iGCSMavLinkInterface alloc] init];
    interface.mainVC = mainVC;
    appMLI = interface;

    return interface;
}

-(void)setupLogger{
    DateTimeUtils *dtUtils = [[DateTimeUtils alloc] init];
    NSString *logName = [dtUtils dateStringInUTCWithExtension:@"log"];
    _mavlinkLogger = [[MavLinkLogger alloc] initWithLogName:logName];
}

static void send_uart_bytes(mavlink_channel_t chan, uint8_t *buffer, uint16_t len)
{
    NSLog(@"iGCSMavLinkInterface:send_uart_bytes: sending %hu chars to connection pool", len);
    [appMLI produceData:buffer length:len];
}

// MavLink destination override
-(void)consumeData:(uint8_t*)bytes length:(int)length
{
    @autoreleasepool {
        
        // Notify the comms view of receipt of n bytes
        [self.mainVC.commsVC bytesReceived: length];
        
        // set up log file the first time we get any data
        if (!_mavlinkLogger) {
            [self setupLogger];
        }

        // Pass each byte to the MAVLINK parser
        for (unsigned int byteIdx = 0; byteIdx < length; byteIdx++) {
            if (mavlink_parse_char(MAVLINK_COMM_0, bytes[byteIdx], &msg, &status)) {
                // We completed a packet, so...
                switch (msg.msgid) {
                    case MAVLINK_MSG_ID_HEARTBEAT:
                        [Logger console:@"MavLink Heartbeat."];
                        
                        // If we haven't gotten anything but heartbeats in 5 seconds re-request the messages
                        if (++self.heartbeatOnlyCount >= 5) {
                            self.mavLinkInitialized = NO;
                        }
                        
                        if (!self.mavLinkInitialized) {
                            
                            self.mavLinkInitialized = YES;
                            
                            // Decode the heartbeat message
                            mavlink_msg_heartbeat_decode(&msg, &heartbeat);
                            mavlink_system.sysid  = msg.sysid;
                            mavlink_system.compid = (msg.compid+1) % 255; // Use a compid that is distinct from the vehicle's
                            
                            [Logger console:@"Sending request for MavLink messages."];
                            
                            // Send requests to set the stream rates
                            mavlink_msg_request_data_stream_send(MAVLINK_COMM_0, msg.sysid, msg.compid,
                                                                 MAV_DATA_STREAM_ALL, 0, 0); // stop all
                            
                            mavlink_msg_request_data_stream_send(MAVLINK_COMM_0, msg.sysid, msg.compid,
                                                                 MAV_DATA_STREAM_RAW_SENSORS, RATE_RAW_SENSORS, 1);
                            mavlink_msg_request_data_stream_send(MAVLINK_COMM_0, msg.sysid, msg.compid,
                                                                 MAV_DATA_STREAM_RC_CHANNELS, RATE_RC_CHANNELS, 1);
                            mavlink_msg_request_data_stream_send(MAVLINK_COMM_0, msg.sysid, msg.compid,
                                                                 MAV_DATA_STREAM_RAW_CONTROLLER, RATE_RAW_CONTROLLER, 1);
                            mavlink_msg_request_data_stream_send(MAVLINK_COMM_0, msg.sysid, msg.compid,
                                                                 MAV_DATA_STREAM_EXTENDED_STATUS, RATE_CHAN2, 1);
                            mavlink_msg_request_data_stream_send(MAVLINK_COMM_0, msg.sysid, msg.compid,
                                                                 MAV_DATA_STREAM_POSITION, RATE_GPS_POS_INT, 1);
                            mavlink_msg_request_data_stream_send(MAVLINK_COMM_0, msg.sysid, msg.compid,
                                                                 MAV_DATA_STREAM_EXTRA1, RATE_ATTITUDE, 1);
                            mavlink_msg_request_data_stream_send(MAVLINK_COMM_0, msg.sysid, msg.compid,
                                                                 MAV_DATA_STREAM_EXTRA2, RATE_VFR_HUD, 1);
                            mavlink_msg_request_data_stream_send(MAVLINK_COMM_0, msg.sysid, msg.compid,
                                                                 MAV_DATA_STREAM_EXTRA3, RATE_EXTRA3, 1);
                            
                            [self issueStartReadMissionRequest];
                        }
                        break;
                        
                    // Mission reception
                    case MAVLINK_MSG_ID_MISSION_COUNT:
                    {
                        [Logger console:@"MavLink MissionCount."];
                        
                        mavlink_mission_count_t count;
                        mavlink_msg_mission_count_decode(&msg, &count);
                        
                        mavlinkRequestAttempts = 0;
                        self.rxWaypoints = [[WaypointsHolder alloc] initWithExpectedCount:count.count];
                        [self requestNextWaypointOrACK:self.rxWaypoints];
                    }
                        break;
                        
                    case MAVLINK_MSG_ID_MISSION_ITEM:
                    {
                        [Logger console:@"MavLink MissionItem."];
                        
                        mavlink_mission_item_t waypoint;
                        mavlink_msg_mission_item_decode(&msg, &waypoint);
                        
                        mavlinkRequestAttempts = 0;
                        [self.rxWaypoints addWaypoint:waypoint];
                        [self requestNextWaypointOrACK:self.rxWaypoints];
                    }
                        break;
                        

                    // Mission transmission
                    case MAVLINK_MSG_ID_MISSION_ACK:
                        [NSObject cancelPreviousPerformRequestsWithTarget:self];
                        
                        // FIXME: boolean should reflect that we were in a sending transaction, and that we've sent the last waypoint
                        [self endMavLinkTransactionWithSuccess: YES];
                        break;
                    
                    case MAVLINK_MSG_ID_MISSION_REQUEST:
                    {
                        mavlink_mission_request_t request;
                        mavlink_msg_mission_request_decode(&msg, &request);
                        
                        mavlinkRequestAttempts = 0;
                        [self sendMissionItemRequest: [NSNumber numberWithUnsignedInt:request.seq]];
                    }
                        break;
                }
                
                // If we get any other message than heartbeat, we are getting the messages we requested
                if (msg.msgid != MAVLINK_MSG_ID_HEARTBEAT) {
                    self.heartbeatOnlyCount = 0;
                }
                
                // Then send the packet on to the child views
#if 0
                for (id view in [self viewControllers]) {
                    [view handlePacket:&msg];
                }
#else
                [self.mainVC.gcsMapVC handlePacket:&msg];
                [self.mainVC.waypointVC handlePacket:&msg];
                [self.mainVC.commsVC  handlePacket:&msg];
                [self.mavlinkLogger handlePacket:&msg];
#endif
            }
        }
    }
}


///////////////////////////////////////////////////////////////////////////////////////
// General mission transaction handling
// c.f. http://qgroundcontrol.org/mavlink/waypoint_protocol#communication_state_machine
///////////////////////////////////////////////////////////////////////////////////////

- (void) prepareToStartMavlinkTransaction:(NSString*)title {
    mavlinkRequestAttempts = 0;
    // FIXME: replace with custom view, with progress bar, modal until success/failure etc
    mavlinkTransactionProgressDialog = [[UIAlertView alloc] initWithTitle:title
                                                              message:@"Starting Request..."
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel" // FIXME: not really. This view should be modal.
                                                    otherButtonTitles:nil];
    [mavlinkTransactionProgressDialog show];
}

- (void) updateMavlinkTransactionStatus:(NSString*)message {
    [mavlinkTransactionProgressDialog
     setMessage:(mavlinkRequestAttempts == 1) ? message : [NSString stringWithFormat:@"%@ - attempt %d", message, mavlinkRequestAttempts]];
}

- (void) endMavLinkTransactionWithSuccess:(BOOL)success {
    if (success) {
        [mavlinkTransactionProgressDialog dismissWithClickedButtonIndex:0 animated:YES];
    } else {
        [mavlinkTransactionProgressDialog setMessage:@"Failed"];
    }
}


///////////////////////////////////////////////////////////////////////////////////////
// Mission transaction: receiving
///////////////////////////////////////////////////////////////////////////////////////

// FIXME: Find an idiomatic way to represent the "cancel/if retries left/updatestatus" that is
//  repeated in the various mission transmission functions
//   - something like a generic method which took COMPLETED?, DO, and FAILURE closures,
//     and would call FAILURE if too many retries, test COMPLETED? and then conditionally
//     DO and RETRY itself with a delayed performSelector.
//
- (void) issueStartReadMissionRequest {
    [self prepareToStartMavlinkTransaction:@"Requesting Mission"];
    [self requestMissionList];
}

- (void) requestMissionList {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (mavlinkRequestAttempts++ < iGCS_MAVLINK_MAX_RETRIES) {
        [self updateMavlinkTransactionStatus:@"Initiating Request"];

        // Start Read MAV waypoint protocol transaction
        mavlink_msg_mission_request_list_send(MAVLINK_COMM_0, msg.sysid, msg.compid);

        [self performSelector:@selector(requestMissionList) withObject:nil afterDelay:iGCS_MAVLINK_RETRANSMISSION_TIMEOUT];
    } else {
        [self endMavLinkTransactionWithSuccess: NO];
    }
}

- (void) requestNextWaypointOrACK:(WaypointsHolder*)waypoints {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (mavlinkRequestAttempts++ < iGCS_MAVLINK_MAX_RETRIES) {
        
        if ([waypoints allWaypointsReceivedP]) {
            [self endMavLinkTransactionWithSuccess: YES];

            // Finish Read MAV waypoint protocol transaction
            mavlink_msg_mission_ack_send(MAVLINK_COMM_0, msg.sysid, msg.compid, 0);
            
            // Let the GCSMapView and WaypointsView know we've got new waypoints
            //NSLog(@"Loading mission:\n%@", [waypoints toOutputFormat]);
            [self.mainVC.gcsMapVC   resetWaypoints: waypoints];
            [self.mainVC.waypointVC resetWaypoints: waypoints];

        } else {
            [self updateMavlinkTransactionStatus:[NSString stringWithFormat:@"Getting Waypoint #%d", [waypoints numWaypoints]]];
            
            // Request the next waypoint
            mavlink_msg_mission_request_send(MAVLINK_COMM_0, msg.sysid, msg.compid, [waypoints numWaypoints]);

            [self performSelector:@selector(requestNextWaypointOrACK:) withObject:waypoints afterDelay:iGCS_MAVLINK_RETRANSMISSION_TIMEOUT];
        }
        
    } else {
        [self endMavLinkTransactionWithSuccess: NO];
    }
}


///////////////////////////////////////////////////////////////////////////////////////
// Mission transaction: sending
///////////////////////////////////////////////////////////////////////////////////////
- (void)issueStartWriteMissionRequest:(WaypointsHolder*)waypoints {
    // FIXME: handle synchronization issues, like if we're already sending or receiving a mission
    self.txWaypoints = waypoints;
    
    [self prepareToStartMavlinkTransaction:@"Transmitting Mission"];
    [self transmitMissionCount:self.txWaypoints];
}

- (void) transmitMissionCount:(WaypointsHolder*)waypoints {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (mavlinkRequestAttempts++ < iGCS_MAVLINK_MAX_RETRIES) {
        [self updateMavlinkTransactionStatus:@"Sending Waypoint count"];
        
        // Send the vehicle the new mission count, and await WAYPOINT request responses
        mavlink_msg_mission_count_send(MAVLINK_COMM_0, msg.sysid, msg.compid, self.txWaypoints.numWaypoints);

        [self performSelector:@selector(transmitMissionCount:) withObject:waypoints afterDelay:iGCS_MAVLINK_RETRANSMISSION_TIMEOUT];
    } else {
        [self endMavLinkTransactionWithSuccess: NO];
    }
}

- (void)sendMissionItemRequest:(NSNumber*)itemNumber {
    // FIXME: ugh, member variable txWaypoints. Perhaps package item into an NSObject before calling this method to avoid this dependency?
    // FIXME: And check sequenceNumber is in range
    unsigned int itemNum = [itemNumber unsignedIntValue];
    mavlink_mission_item_t item = [self.txWaypoints getWaypoint:itemNum];
    
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    if (mavlinkRequestAttempts++ < iGCS_MAVLINK_MAX_RETRIES) {
        [self updateMavlinkTransactionStatus:[NSString stringWithFormat:@"Sending Waypoint #%d", itemNum]];
        
        // Send the requested mission item
        //   - for now, we assume that all coords are in the MAV_FRAME_GLOBAL_RELATIVE_ALT
        //     frame; see also issueGOTOCommand
        mavlink_msg_mission_item_send(MAVLINK_COMM_0, msg.sysid, msg.compid, itemNum, MAV_FRAME_GLOBAL_RELATIVE_ALT, item.command,
                                      0,
                                      item.autocontinue, item.param1, item.param2, item.param3, item.param4,
                                      item.x, item.y, item.z);

        [self performSelector:@selector(sendMissionItemRequest:) withObject:itemNumber afterDelay:iGCS_MAVLINK_RETRANSMISSION_TIMEOUT];
    } else {
        [self endMavLinkTransactionWithSuccess: NO];
    }
}


///////////////////////////////////////////////////////////////////////////////////////
// Miscellaneous requests
///////////////////////////////////////////////////////////////////////////////////////

- (void) issueGOTOCommand:(CLLocationCoordinate2D)coordinates withAltitude:(float)altitude {
     mavlink_msg_mission_item_send(MAVLINK_COMM_0, msg.sysid, msg.compid, 0, MAV_FRAME_GLOBAL_RELATIVE_ALT, MAV_CMD_NAV_WAYPOINT,
                                   2, // Special flag that indicates this is a GUIDED mode packet
                                   0, 0, 0, 0, 0,
                                   coordinates.latitude, coordinates.longitude, altitude);
    // FIXME: should check for ACK, and retry a few times if not ACKnowledged
}

- (void) issueSetAUTOModeCommand {
    for (unsigned int i = 0; i < 2; i++) {
        mavlink_msg_set_mode_send(MAVLINK_COMM_0, msg.sysid, MAV_MODE_FLAG_CUSTOM_MODE_ENABLED, AUTO);
        [NSThread sleepForTimeInterval:0.01];
    }
}


- (void) loadDemoMission {
    WaypointsHolder* demo = [WaypointsHolder createDemoMission];
    //NSLog(@"Loading mission:\n%@", [[WaypointsHolder createFromQGCString:[demo toOutputFormat]] toOutputFormat]);
    
    [self.mainVC.gcsMapVC resetWaypoints: demo];
    [self.mainVC.waypointVC resetWaypoints: demo];
}

@end
