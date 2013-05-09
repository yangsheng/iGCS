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
    
    DBPath *path = [self findDataFile];
    
    if (path)
    {
        DBFile *dataFile = [[DBFilesystem sharedFilesystem] openFile:path error:nil];
        
        NSData *data = [dataFile readData:nil];
        
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        
        NSArray *packetArray = [unarchiver decodeObjectForKey:kStreamPacketArrayKey];
        
        self.packetBuffer = packetArray;
        self.bufferIndex = 0;
        
        NSLog(@"Loaded packet buffer with %i packets.",[self.packetBuffer count]);
    }
    else
    {
        NSLog(@"Error: Could not open data file for streaming...");
    }
    
    
    
    // FIXME: Handle errors
}

-(DBPath*)findDataFile
{
    NSString *streamsFolder = @"streams";
    
    DBPath *streamsPath = [[DBPath root] childPath:streamsFolder];
    
    NSArray *logFiles = [[DBFilesystem sharedFilesystem] listFolder:streamsPath error:nil];
    
    DBFileInfo *targetFile;
    for (DBFileInfo *fileInfo in logFiles)
    {
        targetFile = fileInfo;
        break;
    }
    
    if (targetFile)
    {
        return targetFile.path;
    }
    else
    {
        return nil;
    }
}

-(void)startPlayback
{
    self.playbackTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self
                                   selector:@selector(playbackTick) userInfo:nil repeats:YES];
    self.playbackStartTime = [NSDate date];
}



// called periodically by NSTimer to stream playback data
-(void)playbackTick
{
    NSLog(@"Playback tick.");
    // Reset to beginning of log if end is reached
    if (self.bufferIndex == [self.packetBuffer count])
    {
        self.bufferIndex = 0;
        self.playbackStartTime = [NSDate date];
    }
    
    StreamPacket *currentPacket = [self.packetBuffer objectAtIndex:self.bufferIndex];
    StreamPacket *firstPacket = [self.packetBuffer objectAtIndex:0];
    
    NSTimeInterval currentPlaybackTime = [[NSDate date] timeIntervalSinceDate:self.playbackStartTime];
    
    NSTimeInterval packetPlaybackTime = [currentPacket.timeStamp timeIntervalSinceDate:firstPacket.timeStamp];
    
    // Send all packets with timestamp less than current playback iteration timestamp
    while (packetPlaybackTime < currentPlaybackTime)
    {
        NSLog(@"Streaming %i bytes: %@",[currentPacket.packetData length],currentPacket.timeStamp);
        
        // Instrument bytes
        /*
        NSString *bytesString = @"";
        uint8_t *bytes = (uint8_t*)[currentPacket.packetData bytes];
        
        for(unsigned int bIdx = 0; bIdx < [currentPacket.packetData length]; bIdx++)
        {
            bytesString = [NSString stringWithFormat:@"%@ %x",bytesString,bytes[bIdx]];
        }
        NSLog(@"Playback Bytes: %@",bytesString);
         */
        
        [delegate playerProducedData:currentPacket.packetData];
        
        
        
        
        
        self.bufferIndex++;
        
        if (self.bufferIndex < [self.packetBuffer count])
        {
            currentPacket = [self.packetBuffer objectAtIndex:self.bufferIndex];
            packetPlaybackTime = [currentPacket.timeStamp timeIntervalSinceDate:firstPacket.timeStamp];
        }
        else
        {
            NSLog(@"End of playback file reached.");
            break;
        }
    }
    
}

-(void)stop
{
    [self.playbackTimer invalidate];
    self.playbackTimer = nil;
}



@end
