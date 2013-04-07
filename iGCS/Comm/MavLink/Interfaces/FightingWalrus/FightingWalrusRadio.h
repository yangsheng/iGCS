//
//  FightingWalrusRadio.h
//  iGCS
//
//  Created by Andrew Aarestad on 2/22/13.
//
//

#import <Foundation/Foundation.h>
#import "MavLinkInterface.h"
#import "FightingWalrusProtocol.h"


@interface FightingWalrusRadio : MavLinkInterface <FightingWalrusProtocolDelegate>

+(FightingWalrusRadio*)create;



@property (strong) FightingWalrusProtocol *fwProtocol;
@end
