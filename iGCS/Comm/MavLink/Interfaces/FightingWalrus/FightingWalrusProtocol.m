//
//  FightingWalrusProtocol.m
//  iGCS
//
//  Created by Andrew Aarestad on 2/23/13.
//
//

#import "FightingWalrusProtocol.h"

#import "DebugLogger.h"


@interface FightingWalrusProtocol ()

@property (readwrite) uint8_t AccStatus;
@property (readwrite) uint8_t AccMajor;
@property (readwrite) uint8_t AccMinor;
@property (readwrite) uint8_t AccRev;
@property (readwrite) uint8_t BoardID;
@property (readwrite) float temperature;
@property (readwrite) int pot;
@property (readwrite) uint8_t switches;

@end

@implementation FightingWalrusProtocol


@synthesize AccStatus;
@synthesize AccMajor;
@synthesize AccMinor;
@synthesize AccRev;
@synthesize BoardID;
@synthesize temperature;
@synthesize pot;
@synthesize switches;
@synthesize delegate;


- (id) init
{
    // FIXME define protocol name and move to config file
	self = [super initWithProtocol:@"com.fightingwalrus.prototype"];
	[DebugLogger console:@"starting update thread"];
	updateThread = [[NSThread alloc] initWithTarget:self selector:@selector(updateData) object:nil];
	[updateThread start];
    
	BoardID = MFI_UNKNOWN_HW;
    
    
    [self sendMavLinkRequest:@"enableStream"];
    
	//
	return self;
	
}




#define kUPDATERATE_FAST 0.005 // seconds
#define kUPDATERATE_SLOW 0.100 // seconds

- (void) updateData
{
	int c = 0;
	float updateRate = kUPDATERATE_SLOW;
    
	while (1)
	{
		@synchronized (self)
		{
			if(BoardID == MFI_UNKNOWN_HW)
			{
                [self sendStatusRequest];
				
				
			}
			
			if ((++c % (int)(1.0/updateRate))==0) // update the temperature once per second
			{
                [self sendDebugInstrumRequest];
                [self sendMavLinkDataRequest];
			}
            
		}
		if (BoardID == MFI_16_BIT_HW) {
			updateRate = kUPDATERATE_FAST;
		}
		else {
			updateRate = kUPDATERATE_SLOW;
		}
		[NSThread sleepForTimeInterval:updateRate];
	}
}


// Message helpers

-(void) sendStatusRequest
{
    char requestStatus[] = {0,0,0,0,0,0};
    
    [self queueTxBytes:[NSData dataWithBytes:requestStatus length:sizeof(requestStatus)]];
}

- (void) sendDebugInstrumRequest
{
	char requestDebugInstrum[6] = {20,0,0,0,0,0};
    [self queueTxBytes:[NSData dataWithBytes:requestDebugInstrum length:sizeof(requestDebugInstrum)]];
    
}

-(void) sendMavLinkDataRequest
{
    
	char requestMavLinkData[6] = {30,0,0,0,0,0};
    [self queueTxBytes:[NSData dataWithBytes:requestMavLinkData length:sizeof(requestMavLinkData)]];
    
}

-(void) sendMavLinkRequest:(NSString*)requestType
{
    if ([requestType isEqualToString:@"enableStream"])
    {
        
        char requestEnableMavlinkStream[6] = {50,0,0,0,0,0};
        [self queueTxBytes:[NSData dataWithBytes:requestEnableMavlinkStream length:sizeof(requestEnableMavlinkStream)]];
        
    }
    else
    {
        NSLog(@"Error: Did not recognize sendMavLinkRequest requestType: %@",requestType);
    }
}

- (int) readData:(NSData *) data
{
    //[DebugLogger console:@"readData");
	int ret;
	ret = 0;
	if([data length] >= 6)
	{
        int expectedNumBytes = [data length];
        
		NSRange r;
		uint8_t buf[expectedNumBytes];
		r.location = 0;
		r.length = expectedNumBytes;
		ret = r.length;
        
        
        
		[data getBytes:buf length:expectedNumBytes]; // Extract the complete Packet
        
        uint8_t messageType = buf[0];
        
        
        
		// process data received from the accessory
		switch(messageType)
		{
			case 1: // Accessory Ready
				@synchronized (self)
            {
                AccStatus = buf[1];
                AccMajor = buf[2];
                AccMinor = buf[3];
                AccRev = buf[4];
                BoardID = buf[5];
            }
				break;
            case 21: // ReturnDebugInstrum
            {
                //char dataBuffer[expectedNumBytes];
                char tempChar;
                NSMutableArray *messages = [NSMutableArray arrayWithCapacity:1];
                NSString *message = [NSString string];
                for (int bufIdx = 0;bufIdx < expectedNumBytes-1;bufIdx++)
                {
                    tempChar = (char)buf[bufIdx+1];
                    
                    // Messages are delimited by \0
                    if (tempChar == '\0')
                    {
                        [messages addObject:message];
                        message = [NSString string];
                    }
                    else
                    {
                        message = [NSString stringWithFormat:@"%@%c",message,tempChar];
                    }
                }
                [messages addObject:message];
                
                //NSString *parsedMessage = [NSString stringWithUTF8String:(const char *)dataBuffer];
                //NSString *parsedMessage = [NSString stringWithCString:(const char *)dataBuffer encoding:NSUTF8StringEncoding];
                
                // remove final character since stringWithUTF8String converts the trailing NULL to an 'S' for some reason
                //NSString *finalMessage = [parsedMessage substringToIndex:[parsedMessage length]-1];
                [DebugLogger console:@"Received %i debug strings",[messages count]];
                int idx = 1;
                for (NSString *msg in messages)
                {
                    //[DebugLogger console:@"Received message %i: %@",idx,msg];
                    //[Logger logDebug:msg];
                    idx++;
                }
            }
                break;
            case 31: // ReturnMavLinkData
            {
                [DebugLogger console:@"Walrus received MavLink data: %i",expectedNumBytes];
                
                [[self delegate] accessoryProducedData:buf length:expectedNumBytes];
                
                /*MAVMessage *message = [MAVParseMessage parseMAVMessage:data];
                 
                 
                
                if (message)
                {
                    [DebugLogger console:@"Parsed MAVMessage: %@",[message description]);
                }
                else
                {
                    [DebugLogger console:@"Warning: Message data was invalid.");
                }*/
            }
				break;
			default: // unknown command
				[DebugLogger console:@"%@ : Unknown Message: %d",theProtocol,buf[0]];
				break;
		}
	}
	return ret;
}



@end
