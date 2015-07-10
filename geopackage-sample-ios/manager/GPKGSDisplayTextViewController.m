//
//  GPKGSDisplayTextViewController.m
//  geopackage-sample-ios
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)backButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
