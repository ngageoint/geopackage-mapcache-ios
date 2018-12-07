//
//  MCSettingsCoordinator.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/5/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCSettingsCoordinator.h"

@implementation MCSettingsCoordinator

- (void)start {
    MCSettingsViewController *settingsViewController = [[MCSettingsViewController alloc] initAsFullView:YES];
    settingsViewController.drawerViewDelegate = _drawerViewDelegate;
    [settingsViewController.drawerViewDelegate pushDrawer:settingsViewController];
}

@end
