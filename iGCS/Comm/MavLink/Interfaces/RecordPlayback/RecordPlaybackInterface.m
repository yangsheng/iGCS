//
//  RecordPlaybackInterface.m
//  iGCS
//
//  Created by Andrew on 5/8/13.
//
//

#import "RecordPlaybackInterface.h"

@implementation RecordPlaybackInterface


+(RecordPlaybackInterface*) createForRecord
{
    RecordPlaybackInterface *rpi = [[RecordPlaybackInterface alloc] init];
    
    rpi.streamRecorder = [StreamRecorder create];
    
    return rpi;
}

+(RecordPlaybackInterface*) createForPlayback
{
    RecordPlaybackInterface *rpi = [[RecordPlaybackInterface alloc] init];
    
    rpi.streamPlayer = [StreamPlayer createWithDelegate:rpi];
    
    [rpi.streamPlayer startPlayback];
    
    return rpi;
}


-(void)consumeData:(uint8_t *)bytes length:(int)length
{
    if (self.streamRecorder)
    {
        NSData *dataToRecord = [NSData dataWithBytes:bytes length:length];
        
        [self.streamRecorder rx:dataToRecord];
    }
    
}

-(void)stop
{
    if (self.streamRecorder)
    {
        [self.streamRecorder stop];
    }
    else if (self.streamPlayer)
    {
        [self.streamPlayer stop];
    }
}


#pragma mark -
#pragma mark StreamPlayerDelegate methods

-(void)playerProducedData:(NSData *)data
{
    
    // FIXME: Change to NSData passing
    uint8_t *bytes = (uint8_t*)[data bytes];
    [self produceData:bytes length:[data length]];
    
}


@end
