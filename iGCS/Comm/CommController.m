//
//  CommController.m
//  iGCS
//
//  Created by Andrew Aarestad on 2/22/13.
//
//

#import "CommController.h"

#import "DebugViewController.h"

#import "Logger.h"

#import "RNBluetoothInterface.h"
#import "FightingWalrusRadio.h"
#import "Logger.h"


@implementation CommController



static MavLinkConnectionPool *connections;
static MainViewController *mainVC;

static iGCSMavLinkInterface *appMLI;

static RedparkSerialCable *redParkCable;

static RNBluetoothInterface *rnBluetooth;

static FightingWalrusRadio *fightingWalrusRadio;

//static MavLinkInterface *activeInputInterface;
static NSString *activeInterfaceString;

+(iGCSMavLinkInterface*)appMLI
{
    return appMLI;
}

+(NSString*)getActiveInterfaceString
{
    return activeInterfaceString;
}

// called at startup for app to initialize interfaces
// input: instance of MainViewController - used to trigger view updates during comm operations
+(void)start:(MainViewController*)mvc
{
    @try {
        connections = [[MavLinkConnectionPool alloc] init];
        
        mainVC = mvc;
        
        [self createDefaultConnections];
        
        [Logger console:@"Created default connections in CommController."];
    }
    @catch (NSException *exception) {
        [Logger dumpException:exception];
    }
    
    
    
    
    
    
}



// TODO: Move this stuff to user defaults controllable in app views
+(void)createDefaultConnections
{
    
    appMLI = [iGCSMavLinkInterface createWithViewController:mainVC];
    
    
    
    
    
    [self startRedpark];
    
    
    //[self startFWR];
    
    
    
    
}


+(void)resetConnectionPool
{
    [connections closeAllConnections];
    [Logger console:@"Closed all connections."];
    
    [self closeAllInterfaces];
    [Logger console:@"Closed all interfaces."];
    
    [connections addDestination:appMLI];
    [Logger console:@"Configured iGCS Application as MavLink consumer."];
}



+(BOOL) startRedpark
{
    [self resetConnectionPool];
    
    if (!redParkCable)
    {
        // configure input connection as redpark cable
        [Logger console:@"Starting Redpark connection."];
        redParkCable = [RedparkSerialCable createWithViews:mainVC];
        
        if (redParkCable)
        {
            [Logger console:@"Redpark started."];
        }
        else
        {
            [Logger console:@"Could not create Redpark!"];
            return NO;
        }
    }
    else
    {
        [Logger console:@"Redpark already started."];
    }
    
    [connections addSource:redParkCable];
    [connections createConnection:redParkCable destination:appMLI];
    [connections createConnection:appMLI destination:redParkCable];
    [Logger console:@"Connected Redpark to iGCS Application."];
    
    activeInterfaceString = [RedparkSerialCable interfaceDescription];
    
    return YES;
}

+(BOOL) startFWR
{
    [self resetConnectionPool];
    
    if (!fightingWalrusRadio)
    {
        fightingWalrusRadio = [FightingWalrusRadio create];
        
        if (fightingWalrusRadio)
        {
            [Logger console:@"Created FWR."];
        }
        else
        {
            [Logger console:@"FWR Could not be created!"];
            return NO;
        }
    }
    
    [connections addSource:fightingWalrusRadio];
    [connections createConnection:fightingWalrusRadio destination:appMLI];
    [connections createConnection:appMLI destination:fightingWalrusRadio];
    [Logger console:@"Connected FWR to iGCS Application."];
    
    activeInterfaceString = [FightingWalrusRadio interfaceDescription];
    
    return YES;
}

+(BOOL) startRNBT
{
    [self resetConnectionPool];
    
    if (!rnBluetooth)
    {
        [Logger console: @"Creating RovingNetworks connection."];
        rnBluetooth = [RNBluetoothInterface create];
        
        if (rnBluetooth)
        {
            [Logger console:@"Created RNBT."];
        }
        else
        {
            [Logger console:@"Could not create RNBT!"];
            return NO;
        }
    }
    else
    {
        [Logger console:@"RN Bluetooth already created."];
    }
    
    [connections addSource:rnBluetooth];
    [connections createConnection:rnBluetooth destination:appMLI];
    [connections createConnection:appMLI destination:rnBluetooth];
    [Logger console:@"Connected RN Bluetooth to iGCS Application."];
    
    activeInterfaceString = [RNBluetoothInterface interfaceDescription];
    
    return YES;
}





+(void) startBluetoothTx
{
    // Start Bluetooth driver
    BluetoothStream *bts = [BluetoothStream createForTx];
    
    
    // Create connection from redpark to bts
    [connections createConnection:redParkCable destination:bts];
    
    
    [Logger console:@"Created BluetoothStream for Tx."];
    
    NSLog(@"Created BluetoothStream for Tx: %@",[bts description]);
    
}

+(void) startBluetoothRx
{
    // Start Bluetooth driver
    BluetoothStream *bts = [BluetoothStream createForRx];
    
    
    // Create connection from redpark to bts
    [connections createConnection:bts destination:appMLI];
    
    
    [Logger console:@"Created BluetoothStream for Rx."];
    NSLog(@"Created BluetoothStream for Rx: %@",[bts description]);
    
    activeInterfaceString = [BluetoothStream interfaceDescription];
    
}


+(void) closeAllInterfaces
{
    [connections closeAllInterfaces];
    
    // Clear static interface variables so objects must be recreated on restart
    fightingWalrusRadio = nil;
    rnBluetooth = nil;
    redParkCable = nil;
}


@end




