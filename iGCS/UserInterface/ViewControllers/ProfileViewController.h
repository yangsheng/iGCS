//
//  ProfileViewController.h
//  iGCS
//
//  Created by Andrew Aarestad on 3/27/13.
//
//

#import <Foundation/Foundation.h>
#import "AppDelegate.h"

@interface ProfileViewController : UIViewController

@property (strong, nonatomic) IBOutlet UIButton *facebookLoginButton;
@property (strong, nonatomic) IBOutlet UILabel *totalFlightHoursLabel;
@property (strong, nonatomic) IBOutlet UILabel *crashesLabel;
@property (strong, nonatomic) IBOutlet UILabel *facebookStatusLabel;

@property (weak) AppDelegate *appDelegate;


@property (strong, nonatomic) IBOutlet UIButton *recordButton;
@property (strong, nonatomic) IBOutlet UIButton *playbackButton;


- (IBAction)facebookLoginButtonPressed:(id)sender;

- (IBAction)playbackButtonClick:(id)sender;

- (IBAction)recordButtonClick:(id)sender;
@end
