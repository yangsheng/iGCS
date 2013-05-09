//
//  StreamRecorder.m
//  iGCS
//
//  Created by Andrew on 5/8/13.
//
//

#import "StreamRecorder.h"
#import "StreamPacket.h"


@implementation StreamRecorder

+(StreamRecorder*)create
{
    StreamRecorder *streamRecorder = [[StreamRecorder alloc] init];
    
    streamRecorder.packetBuffer = [NSMutableArray array];
    
    return streamRecorder;
}

-(void) stop
{
    [self dumpPacketBufferToFile];
    
    [self.packetBuffer removeAllObjects];
}

-(void) rx:(NSData*)rxData
{
    // create packet with timestamp of now
    StreamPacket *packet = [StreamPacket createForData:rxData];
    
    
    [self didReceivePacket:packet];
    
}


-(void) didReceivePacket:(StreamPacket*)packet
{
    [self.packetBuffer addObject:packet];
}

-(void) dumpPacketBufferToFile
{
    DBFile *file = [self createLogFile];
    
    NSMutableData *archiveData = [NSMutableData data];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:archiveData];
    
    // Encode packet array into archiver NSData
    [archiver encodeObject:self.packetBuffer forKey:kStreamPacketArrayKey];
    [archiver finishEncoding];
    
    // Dump archiver NSData to Dropbox file
    [file writeData:archiveData error:nil];
    
    [file close];
    
    // FIXME: Handle errors
    
    
}

/* Streaming not implemented for now
-(void) writePacketToFile:(StreamPacket*)packet
{
    DBFile *logFile;
    
    if (!self.logPath)
    {
        logFile = [self createLogFile];
    }
    else
    {
        logFile = [[DBFilesystem sharedFilesystem] openFile:self.logPath error:nil];
    }
    
    if (logFile)
    {
     
    }
}*/

-(DBFile*)createLogFile
{
    DBPath *newPath = [[DBPath root] childPath:[NSString stringWithFormat:@"streams/stream-%0.0f.dat",[[NSDate date] timeIntervalSince1970]]];
    
    self.logPath = newPath;
    
    DBFile *file = [[DBFilesystem sharedFilesystem] createFile:newPath error:nil];
    
    return file;
}

@end
