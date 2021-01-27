//
//  MCSettingsCoordinator.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/5/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCSettingsCoordinator.h"
#import"mapcache_ios-Swift.h"

@interface MCSettingsCoordinator ()
@property (nonatomic, strong) MCSettingsViewController *settingsViewController;
@property (nonatomic, strong) MCTileServerURLManagerViewController *tileServerManagerView;
@property (nonatomic, strong) MCNewTileServerViewController *createTileServerView;
@property (nonatomic, strong) NSString *originalServerName;
@end

@implementation MCSettingsCoordinator 

- (void)start {
    self.settingsViewController = [[MCSettingsViewController alloc] initAsFullView:YES];
    self.settingsViewController.mapSettingsDelegate = _settingsDelegate;
    self.settingsViewController.drawerViewDelegate = _drawerViewDelegate;
    self.settingsViewController.settingsDelegate = self;
    [self.settingsViewController.drawerViewDelegate pushDrawer:self.settingsViewController];
}


- (void) startForServerSelection {
    self.tileServerManagerView = [[MCTileServerURLManagerViewController alloc] initAsFullView:YES];
    self.tileServerManagerView.drawerViewDelegate = self.drawerViewDelegate;
    self.tileServerManagerView.selectServerDelegate = self.selectServerDelegate;
    self.tileServerManagerView.tileServerManagerDelegate = self;
    [self.drawerViewDelegate pushDrawer:self.tileServerManagerView];
    self.tileServerManagerView.selectMode = YES;
}


#pragma mark - MCSettingsDelegate
- (void)showNoticeAndAttributeView {
    MCNoticeAndAttributionViewController *noticeViewController = [[MCNoticeAndAttributionViewController alloc] initAsFullView:YES];
    noticeViewController.drawerViewDelegate = self.drawerViewDelegate;
    [self.drawerViewDelegate pushDrawer:noticeViewController];
}


- (void)showTileURLManager {
    /*self.tileServerManagerView = [[MCTileServerURLManagerViewController alloc] initAsFullView:YES];
    self.tileServerManagerView.drawerViewDelegate = self.drawerViewDelegate;
    self.tileServerManagerView.tileServerManagerDelegate = self;
    [self.drawerViewDelegate pushDrawer:self.tileServerManagerView];*/
    
    self.originalServerName = nil;
    self.createTileServerView = [[MCNewTileServerViewController alloc] initAsFullView:YES];
    self.createTileServerView.drawerViewDelegate = self.drawerViewDelegate;
    self.createTileServerView.saveTileServerDelegate = self;
    [self.drawerViewDelegate pushDrawer:self.createTileServerView];
}


#pragma mark - MCTileServerManagerDelegate
- (void) showNewTileServerView {
    self.originalServerName = nil;
    self.createTileServerView = [[MCNewTileServerViewController alloc] initAsFullView:YES];
    self.createTileServerView.drawerViewDelegate = self.drawerViewDelegate;
    self.createTileServerView.saveTileServerDelegate = self;
    [self.drawerViewDelegate pushDrawer:self.createTileServerView];
}


- (void)editTileServer:(NSString *)serverName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *serverUrls = [defaults dictionaryForKey:MC_SAVED_TILE_SERVER_URLS];
    self.originalServerName = serverName;
    
    if (serverUrls != nil) {
        self.createTileServerView = [[MCNewTileServerViewController alloc] initAsFullView:YES];
        self.createTileServerView.drawerViewDelegate = self.drawerViewDelegate;
        self.createTileServerView.saveTileServerDelegate = self;
        [self.drawerViewDelegate pushDrawer:self.createTileServerView];
        [self.createTileServerView setServerName:serverName];
        [self.createTileServerView setServerURL:[serverUrls objectForKey:serverName]];
    }
}


- (void)deleteTileServer:(nonnull NSString *)serverName {
    [[MCTileServerRepository shared] removeTileServerFromUserDefaultsWithServerName:serverName];
    [self.settingsViewController update];
}


#pragma mark - MCTileServerSaveDelegate
- (BOOL)saveURL:(NSString *)url forServerNamed:(NSString *)serverName tileServer:(nonnull MCTileServer *)tileServer {
    // If the server name changed, remove the old value
    if (self.originalServerName != nil && ![self.originalServerName isEqualToString:serverName]) {
        [[MCTileServerRepository shared] removeTileServerFromUserDefaultsWithServerName:self.originalServerName];
    }
    
    BOOL didUpdate = [[MCTileServerRepository shared] saveToUserDefaultsWithServerName:serverName url:url tileServer:tileServer];
    [self.settingsViewController update];
    return didUpdate;
}

@end
