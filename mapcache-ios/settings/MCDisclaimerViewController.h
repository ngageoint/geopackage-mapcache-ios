//
//  MCDisclaimerViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 6/14/19.
//  Copyright © 2019 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCColorUtil.h"

NS_ASSUME_NONNULL_BEGIN

@interface MCDisclaimerViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *continueButton;
@property (weak, nonatomic) IBOutlet UISwitch *agreeSwitch;
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

NS_ASSUME_NONNULL_END
