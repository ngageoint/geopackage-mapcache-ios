//
//  MCSettingsCoordinator.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/5/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCSettingsCoordinator.h"

@interface MCSettingsCoordinator ()
@property (nonatomic, strong) MCTileServerURLManagerViewController *tileServerManagerView;
@property (nonatomic, strong) MCNewTileServerViewController *createTileServerView;
@property (nonatomic, strong) NSString *originalServerName;
@end

@implementation MCSettingsCoordinator 

- (void)start {
    MCSettingsViewController *settingsViewController = [[MCSettingsViewController alloc] initAsFullView:YES];
    settingsViewController.mapSettingsDelegate = _settingsDelegate;
    settingsViewController.drawerViewDelegate = _drawerViewDelegate;
    settingsViewController.settingsDelegate = self;
    [settingsViewController.drawerViewDelegate pushDrawer:settingsViewController];
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
    self.tileServerManagerView = [[MCTileServerURLManagerViewController alloc] initAsFullView:YES];
    self.tileServerManagerView.drawerViewDelegate = self.drawerViewDelegate;
    self.tileServerManagerView.tileServerManagerDelegate = self;
    [self.drawerViewDelegate pushDrawer:self.tileServerManagerView];
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *serverUrls = [[NSMutableDictionary alloc] initWithDictionary:[defaults dictionaryForKey:MC_SAVED_TILE_SERVER_URLS]];
    
    [serverUrls removeObjectForKey:serverName];
    [defaults setObject:serverUrls forKey:MC_SAVED_TILE_SERVER_URLS];
    [defaults synchronize];
    [self.tileServerManagerView update];
}


#pragma mark - MCTileServerSaveDelegate
- (BOOL)saveURL:(NSString *)url forServerNamed:(NSString *)serverName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *serverUrls = [[NSMutableDictionary alloc] initWithDictionary:[defaults dictionaryForKey:MC_SAVED_TILE_SERVER_URLS]];
    
    if (serverUrls == nil || [[serverUrls allKeys] count] == 0) {
        serverUrls = [[NSMutableDictionary alloc] init];
    }
    
    // If the server name changed, remove the old value
    if (self.originalServerName != nil && ![self.originalServerName isEqualToString:serverName]) {
        [serverUrls removeObjectForKey:_originalServerName];
    }
    
    [serverUrls setValue:url forKey:serverName];
    [defaults setObject:serverUrls forKey:MC_SAVED_TILE_SERVER_URLS];
    [defaults synchronize];
    [self.tileServerManagerView update];
    
    return YES;
}

@end
