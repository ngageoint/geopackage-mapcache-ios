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
    settingsViewController.settingsDelegate = _settingsDelegate;
    settingsViewController.drawerViewDelegate = _drawerViewDelegate;
    settingsViewController.noticeAndAttributeDelegate = self;
    [settingsViewController.drawerViewDelegate pushDrawer:settingsViewController];
}


#pragma mark - MCNoticeAndAttributeDelegate
- (void)showNoticeAndAttributeView {
    MCNoticeAndAttributionViewController *noticeViewController = [[MCNoticeAndAttributionViewController alloc] initAsFullView:YES];
    noticeViewController.drawerViewDelegate = self.drawerViewDelegate;
    [self.drawerViewDelegate pushDrawer:noticeViewController];
}

@end
