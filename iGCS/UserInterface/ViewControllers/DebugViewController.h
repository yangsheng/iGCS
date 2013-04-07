//
//  DebugViewController.h
//  iGCS
//
//  Created by Andrew Aarestad on 2/25/13.
//
//

#import <UIKit/UIKit.h>

@interface DebugViewController : UIViewController


@property (strong, nonatomic) IBOutlet UITextView *consoleTextView;
@property (strong, nonatomic) IBOutlet UITextView *errorsTextView;

@property (strong) NSMutableArray *pendingConsoleMessages;
@property (strong) NSMutableArray *pendingErrorMessages;

@property (strong, nonatomic) IBOutlet UILabel *activeInterfaceLabel;


- (IBAction)bluetoothRxClicked:(id)sender;
- (IBAction)bluetoothTxClicked:(id)sender;

- (IBAction)enableRedpark:(id)sender;
- (IBAction)enableFWR:(id)sender;
- (IBAction)enableRNBT:(id)sender;

-(void)consoleMessage:(NSString*)messageText;
-(void)errorMessage:(NSString*)messageText;


@end
