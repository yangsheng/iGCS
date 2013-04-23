//
//  FightingWalrusRadio.m
//  iGCS
//
//  Created by Andrew Aarestad on 2/22/13.
//
//

#import "FightingWalrusRadio.h"
#import "DebugLogger.h"


@implementation FightingWalrusRadio



+(NSString*)interfaceDescription { return @"Fighting Walrus Radio"; }



+(FightingWalrusRadio*)create
{
    FightingWalrusRadio *fwr = [[FightingWalrusRadio alloc] init];
    
    
    [DebugLogger console:@"FightingWalrusRadio: Starting accessory session.."];
    
    fwr.fwProtocol = [[FightingWalrusProtocol alloc] init];
    
    fwr.fwProtocol.delegate = fwr;
    
    return fwr;
    
    
}



-(void)consumeData:(uint8_t *)bytes length:(int)length
{
    [DebugLogger console:@"FightingWalrusRadio: consumeData (%i bytes)",length];
    
    [self.fwProtocol queueTxBytes:[NSData dataWithBytes:bytes length:length]];
    
}



// FightingWalrusProtocolDelegate methods

-(void)accessoryProducedData:(uint8_t*)bytes length:(int)length
{
    [DebugLogger console:@"FWR: accessoryProducedData: %i bytes",length];
    [self produceData:bytes length:length];
}



@end
