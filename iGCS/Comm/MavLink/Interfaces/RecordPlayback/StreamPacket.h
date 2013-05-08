//
//  StreamPacket.h
//  iGCS
//
//  Created by Andrew on 5/8/13.
//
//

#import <Foundation/Foundation.h>

#define kStreamPacketArrayKey @"StreamPacketArray"

@interface StreamPacket : NSObject <NSCoding>


+(StreamPacket*)createForData:(NSData*)data;


@property (strong) NSData *packetData;
@property (strong) NSDate *timeStamp;

@end
