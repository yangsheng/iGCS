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





+(FightingWalrusRadio*)create
{
    FightingWalrusRadio *fwr = [[FightingWalrusRadio alloc] init];
    
    
    [DebugLogger console:@"FightingWalrusRadio: Starting accessory session.."];
    
    fwr.fwProtocol = [[FightingWalrusProtocol alloc] init];
    
    return fwr;
    
    
}



-(void)consumeData:(uint8_t *)bytes length:(int)length
{
    [DebugLogger console:@"FightingWalrusRadio: consumeData (stubbed)."];
    
    //NSData *dataToStream = [NSData dataWithBytes:bytes length:length];
    //[self writeData:dataToStream];
    
}



// FightingWalrusProtocolDelegate methods

-(void)accessoryProducedData:(uint8_t*)bytes length:(int)length
{
    [self produceData:bytes length:length];
}



@end
