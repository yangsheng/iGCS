//
//  StreamPlayer.m
//  iGCS
//
//  Created by Andrew on 5/8/13.
//
//

#import "StreamPlayer.h"

@implementation StreamPlayer

@synthesize delegate;

+(StreamPlayer*)createWithDelegate:(id<StreamPlayerDelegate>)delegate
{
    StreamPlayer *streamPlayer = [[StreamPlayer alloc] init];
    
    streamPlayer.delegate = delegate;
    
    return streamPlayer;
}


-(void)startPlayback
{
    [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
                                   selector:@selector(playbackTick) userInfo:nil repeats:YES];
}



// called periodically by NSTimer to stream playback data
-(void)playbackTick
{
    
    
}

-(void)stop
{
    
}



@end
