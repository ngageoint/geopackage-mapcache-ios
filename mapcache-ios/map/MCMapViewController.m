//
//  MCMapViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 8/27/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCMapViewController.h"

@interface MCMapViewController ()
@property (strong, nonatomic) NSMutableArray *childCoordinators;
@end


@implementation MCMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _childCoordinators = [[NSMutableArray alloc] init];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) addBottomSheetView {
    NGADrawerCoordinator *drawerCoordinator = [[NGADrawerCoordinator alloc] init];
    [drawerCoordinator start];
    [_childCoordinators addObject: drawerCoordinator];
}

@end
