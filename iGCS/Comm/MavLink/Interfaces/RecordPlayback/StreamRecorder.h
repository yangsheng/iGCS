//
//  StreamRecorder.h
//  iGCS
//
//  Created by Andrew on 5/8/13.
//
//

#import <Foundation/Foundation.h>

#import <Dropbox/Dropbox.h>

@interface StreamRecorder : NSObject

+(StreamRecorder*)create;

-(void) rx:(NSData*)rxData;
-(void) stop;


@property (strong) DBPath *logPath;
@property (strong) NSMutableArray *packetBuffer;

@end
