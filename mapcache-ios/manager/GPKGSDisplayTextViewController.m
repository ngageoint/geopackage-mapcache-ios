//
//  GPKGSDisplayTextViewController.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSDisplayTextViewController.h"

@interface GPKGSDisplayTextViewController ()

@end

@implementation GPKGSDisplayTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.titleButton setTitle:self.titleValue forState:UIControlStateNormal];
    [self.textView setText:self.textValue];
}

- (IBAction)backButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
