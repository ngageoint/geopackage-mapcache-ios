//
//  MCSettingsViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/5/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCSettingsViewController.h"

@interface MCSettingsViewController ()

@end

@implementation MCSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self addDragHandle];
    [self addCloseButton];
}


- (void) closeDrawer {
    [super closeDrawer];
    [self.drawerViewDelegate popDrawer];
}

@end
