//
//  GPKGSDisplayTextViewController.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GPKGSDisplayTextViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *titleButton;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic, strong)  NSString *titleValue;
@property (nonatomic, strong)  NSString *textValue;

@end
