//
//  CommController.m
//  iGCS
//
//  Created by Andrew Aarestad on 2/22/13.
//
//

#import "CommController.h"

#import "DebugViewController.h"

#import "DebugLogger.h"

#import "RNBluetoothInterface.h"
#import "FightingWalrusRadio.h"



@implementation CommController



static MavLinkConnectionPool *connections;
static MainViewController *mainVC;

static iGCSMavLinkInterface *appMLI;

static RedparkSerialCable *redParkCable;

static RNBluetoothInterface *rnBluetooth;

static FightingWalrusRadio *fightingWalrusRadio;

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
        
        [DebugLogger console:@"Created default connections in CommController."];
    }
    @catch (NSException *exception) {
        [DebugLogger dumpException:exception];
    }
    
    
    
    
    
    
}



// TODO: Move this stuff to user defaults controllable in app views
+(void)createDefaultConnections
{
    
    appMLI = [iGCSMavLinkInterface createWithViewController:mainVC];
    [connections addDestination:appMLI];
    [DebugLogger console:@"Configured iGCS Application as MavLink consumer."];
    
    
    
    
    [self startRedpark];
    
    
    
    
}



+(BOOL) startRedpark
{
    // Prevent redundant connections
    [connections closeAllConnections];
    
    if (!redParkCable)
    {
        // configure input connection as redpark cable
        [DebugLogger console:@"Starting Redpark connection."];
        redParkCable = [RedparkSerialCable createWithViews:mainVC];
        
        if (redParkCable)
        {
            [DebugLogger console:@"Redpark started."];
        }
        else
        {
            [DebugLogger console:@"Could not create Redpark!"];
            return NO;
        }
    }
    else
    {
        [DebugLogger console:@"Redpark already started."];
    }
    
    [connections addSource:redParkCable];
    [connections createConnection:redParkCable destination:appMLI];
    [connections createConnection:appMLI destination:redParkCable];
    [DebugLogger console:@"Connected Redpark to iGCS Application."];
    
    activeInterfaceString = @"Redpark";
    
    return YES;
}

+(BOOL) startFWR
{
    // Prevent redundant connections
    [connections closeAllConnections];
    
    if (!fightingWalrusRadio)
    {
        fightingWalrusRadio = [FightingWalrusRadio create];
        
        if (fightingWalrusRadio)
        {
            [DebugLogger console:@"Created FWR."];
        }
        else
        {
            [DebugLogger console:@"FWR Could not be created!"];
            return NO;
        }
    }
    
    [connections addSource:fightingWalrusRadio];
    [connections createConnection:fightingWalrusRadio destination:appMLI];
    [connections createConnection:appMLI destination:fightingWalrusRadio];
    [DebugLogger console:@"Connected FWR to iGCS Application."];
    
    activeInterfaceString = @"Fighting Walrus";
    
    return YES;
}

+(BOOL) startRNBT
{
    // Prevent redundant connections
    [connections closeAllConnections];
    
    if (!rnBluetooth)
    {
        [DebugLogger console: @"Creating RovingNetworks connection."];
        rnBluetooth = [RNBluetoothInterface create];
        
        if (rnBluetooth)
        {
            [DebugLogger console:@"Created RNBT."];
        }
        else
        {
            [DebugLogger console:@"Could not create RNBT!"];
            return NO;
        }
    }
    else
    {
        [DebugLogger console:@"RN Bluetooth already created."];
    }
    
    [connections addSource:rnBluetooth];
    [connections createConnection:rnBluetooth destination:appMLI];
    [connections createConnection:appMLI destination:rnBluetooth];
    [DebugLogger console:@"Connected RN Bluetooth to iGCS Application."];
    
    activeInterfaceString = @"Roving Networks";
    
    return YES;
}





+(void) startBluetoothTx
{
    // Start Bluetooth driver
    BluetoothStream *bts = [BluetoothStream createForTx];
    
    
    // Create connection from redpark to bts
    [connections createConnection:redParkCable destination:bts];
    
    
    [DebugLogger console:@"Created BluetoothStream for Tx."];
    
    NSLog(@"Created BluetoothStream for Tx: %@",[bts description]);
    
}

+(void) startBluetoothRx
{
    // Start Bluetooth driver
    BluetoothStream *bts = [BluetoothStream createForRx];
    
    
    // Create connection from redpark to bts
    [connections createConnection:bts destination:appMLI];
    
    
    [DebugLogger console:@"Created BluetoothStream for Rx."];
    NSLog(@"Created BluetoothStream for Rx: %@",[bts description]);
    
}


+(void) closeAllInterfaces
{
    [connections closeAllInterfaces];
}


@end




