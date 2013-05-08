//
//  StreamPacket.m
//  iGCS
//
//  Created by Andrew on 5/8/13.
//
//

#import "StreamPacket.h"

@implementation StreamPacket


+(StreamPacket*)createForData:(NSData*)data
{
    StreamPacket *sp = [[StreamPacket alloc] initWithData:data timeStamp:[NSDate date]];
    return sp;
}

-(StreamPacket*)initWithData:(NSData*)data timeStamp:(NSDate*)timeStamp;
{
    self.packetData = data;
    self.timeStamp = timeStamp;
    
    return self;
}



#pragma mark NSCoding

#define kPacketDataKey       @"PacketData"
#define kTimeStampKey        @"TimeStamp"

- (void) encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:_packetData forKey:kPacketDataKey];
    [encoder encodeObject:_timeStamp forKey:kTimeStampKey];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    
    NSData *data = [decoder decodeObjectForKey:kPacketDataKey];
    
    NSDate *timeStamp = [decoder decodeObjectForKey:kTimeStampKey];
    
    return [self initWithData:data timeStamp:timeStamp];
}

@end
