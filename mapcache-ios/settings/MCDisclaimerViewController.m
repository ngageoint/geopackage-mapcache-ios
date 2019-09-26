//
//  MCDisclaimerViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 6/14/19.
//  Copyright © 2019 NGA. All rights reserved.
//

#import "MCDisclaimerViewController.h"

@interface MCDisclaimerViewController ()

@end

@implementation MCDisclaimerViewController

- (void)viewDidLoad {
    [super viewDidLoad];    
    [self disableButton];

    // iOS 13 dark mode support
    if ([UIColor respondsToSelector:@selector(systemBackgroundColor)]) {
        self.view.backgroundColor = [UIColor systemBackgroundColor];
        [self setModalInPresentation:YES];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }
}


-(void) viewDidAppear:(BOOL)animated {
    [self.textView sizeToFit];
}


- (void) enableButton {
    _continueButton.userInteractionEnabled = YES;
    _continueButton.backgroundColor = [MCColorUtil getAccent];
}


- (void) disableButton {
    _continueButton.userInteractionEnabled = NO;
    _continueButton.backgroundColor = [MCColorUtil getAccentLight];
}


- (IBAction)switchChanged:(id)sender {
    
    if ([sender isOn]) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"preventDisclaimer"];
        [self enableButton];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"preventDisclaimer"];
        [self disableButton];
    }
}


- (IBAction)continueTapped:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
