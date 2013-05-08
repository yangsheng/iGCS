//
//  RecordPlaybackInterface.h
//  iGCS
//
//  Created by Andrew on 5/8/13.
//
//

#import "MavLinkInterface.h"
#import "StreamPlayer.h"
#import "StreamRecorder.h"


@interface RecordPlaybackInterface : MavLinkInterface <StreamPlayerDelegate>

+(RecordPlaybackInterface*) createForRecord;
+(RecordPlaybackInterface*) createForPlayback;

-(void)stop;

@property (strong) StreamPlayer *streamPlayer;
@property (strong) StreamRecorder *streamRecorder;

@end
