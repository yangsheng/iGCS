//
//  StreamPlayer.m
//  iGCS
//
//  Created by Andrew on 5/8/13.
//
//

#import "StreamPlayer.h"
#import <Dropbox/Dropbox.h>
#import "StreamPacket.h"

@implementation StreamPlayer

@synthesize delegate;

+(StreamPlayer*)createWithDelegate:(id<StreamPlayerDelegate>)delegate
{
    StreamPlayer *streamPlayer = [[StreamPlayer alloc] init];
    
    streamPlayer.delegate = delegate;
    
    [streamPlayer openDataFile];
    
    return streamPlayer;
}


-(void)openDataFile
{
    NSString *filePath = @"dummyPath";
    
    DBPath *path = [[DBPath root] childPath:filePath];
    
    DBFile *dataFile = [[DBFilesystem sharedFilesystem] openFile:path error:nil];
    
    NSData *data = [dataFile readData:nil];
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    
    NSArray *packetArray = [unarchiver decodeObjectForKey:kStreamPacketArrayKey];
    
    self.packetBuffer = packetArray;
    self.bufferIndex = 0;
    
    // FIXME: Handle errors
}

-(void)startPlayback
{
    self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self
                                   selector:@selector(playbackTick) userInfo:nil repeats:YES];
    self.playbackStartTime = [NSDate date];
}



// called periodically by NSTimer to stream playback data
-(void)playbackTick
{
    StreamPacket *currentPacket = [self.packetBuffer objectAtIndex:self.bufferIndex];
    StreamPacket *firstPacket = [self.packetBuffer objectAtIndex:0];
    
    NSTimeInterval currentPlaybackTime = [[NSDate date] timeIntervalSinceDate:firstPacket.timeStamp];
    
    // Send all packets with timestamp less than current playback iteration timestamp
    while ([currentPacket.timeStamp timeIntervalSinceDate:firstPacket.timeStamp] < currentPlaybackTime)
    {
        [delegate playerProducedData:currentPacket.packetData];
        self.bufferIndex++;
        currentPacket = [self.packetBuffer objectAtIndex:self.bufferIndex];
    }
    
}

-(void)stop
{
    [self.playbackTimer invalidate];
    self.playbackTimer = nil;
}



@end
