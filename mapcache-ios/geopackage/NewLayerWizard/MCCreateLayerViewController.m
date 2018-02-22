//
//  GPKGSCreateLayerViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/8/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCCreateLayerViewController.h"

@interface MCCreateLayerViewController ()

@end

@implementation MCCreateLayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)featureLayerButtonTapped:(id)sender {
    [_delegate newFeatureLayer];
}


- (IBAction)tileLayerButtonTapped:(id)sender {
    [_delegate newTileLayer];
}

@end
