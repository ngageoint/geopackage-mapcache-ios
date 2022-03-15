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
    MCTileServer *basemapTileServer = [MCTileServerRepository shared].baseMapServer;
    self.settingsViewController = [[MCSettingsViewController alloc] init];
    
    if (basemapTileServer != nil) {
        self.settingsViewController.basemapTileServer = basemapTileServer;
        
        if (basemapTileServer.serverType == MCTileServerTypeWms) {
            MCLayer *basemapLayer = [MCTileServerRepository shared].baseMapLayer;
            if (basemapLayer != nil) {
                self.settingsViewController.basemapLayer = basemapLayer;
            }
        }
    }
    
    self.settingsViewController.mapSettingsDelegate = _settingsDelegate;
    //self.settingsViewController.drawerViewDelegate = _drawerViewDelegate;
    self.settingsViewController.settingsDelegate = self;
    
    self.settingsViewController.modalPresentationStyle = UIModalPresentationPageSheet;
    [self.presentingViewController presentViewController:self.settingsViewController animated:YES completion:nil];
    
    //[self.settingsViewController.drawerViewDelegate pushDrawer:self.settingsViewController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(basemapsLoadedFromUserDefaults:) name:MC_USER_BASEMAP_LOADED_FROM_DEFAULTS object:nil];
}


- (void) startForServerSelection {
    self.tileServerManagerView = [[MCTileServerURLManagerViewController alloc] init];
    //self.tileServerManagerView.drawerViewDelegate = self.drawerViewDelegate;
    self.tileServerManagerView.selectServerDelegate = self.selectServerDelegate;
    self.tileServerManagerView.tileServerManagerDelegate = self;
    self.tileServerManagerView.modalPresentationStyle = UIModalPresentationPageSheet;
    [self.presentingViewController presentViewController:self.tileServerManagerView animated:YES completion:nil];
    self.presentingViewController = self.tileServerManagerView; // in case they choose to create a new one
    //[self.drawerViewDelegate pushDrawer:self.tileServerManagerView];
    self.tileServerManagerView.selectMode = YES;
}


- (void)basemapsLoadedFromUserDefaults:(NSNotification *)notification {
    self.settingsViewController.basemapTileServer = [[MCTileServerRepository shared] baseMapServer];
    self.settingsViewController.basemapLayer = [[MCTileServerRepository shared] baseMapLayer];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.settingsViewController update];
    });
}


#pragma mark - MCSettingsDelegate
- (void)showNoticeAndAttributeView {
    MCNoticeAndAttributionViewController *noticeViewController = [[MCNoticeAndAttributionViewController alloc] init];
    noticeViewController.modalPresentationStyle = UIModalPresentationPageSheet;
    [self.settingsViewController presentViewController:noticeViewController animated:YES completion:nil];
}


- (void)showTileURLManager {
    self.originalServerName = nil;
    self.createTileServerView = [[MCNewTileServerViewController alloc] init];
    self.createTileServerView.modalPresentationStyle = UIModalPresentationPageSheet;
    [self.settingsViewController presentViewController:self.createTileServerView animated:YES completion:nil];
    self.createTileServerView.saveTileServerDelegate = self;
}


- (void)setUserBasemap:(MCTileServer *)tileServer layer:(MCLayer *)layer {
    [[MCTileServerRepository shared] setBasemapWithTileServer:tileServer layer:layer];
    NSString *basemapURL = @"";
    
    if(tileServer == nil) {
        [self.settingsDelegate updateBasemaps:@"" serverType:MCTileServerTypeError];
        return;
    } else if (tileServer.serverType == MCTileServerTypeXyz) {
        basemapURL = tileServer.url;
    } else if (tileServer.serverType == MCTileServerTypeWms) {
        basemapURL = [tileServer urlForLayerWithLayer:layer boundingBoxTemplate:NO];
    }
    
    [self.settingsDelegate updateBasemaps:basemapURL serverType:tileServer.serverType];
}


#pragma mark - MCTileServerManagerDelegate
- (void) showNewTileServerView {
    self.originalServerName = nil;
    self.createTileServerView = [[MCNewTileServerViewController alloc] init];
    self.createTileServerView.saveTileServerDelegate = self;
    self.createTileServerView.modalPresentationStyle = UIModalPresentationPageSheet;
    [self.presentingViewController presentViewController:self.createTileServerView animated:YES completion:nil];
}


- (void)editTileServer:(NSString *)serverName {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDictionary *serverUrls = [defaults dictionaryForKey:MC_SAVED_TILE_SERVER_URLS];
    self.originalServerName = serverName;
    
    if (serverUrls != nil) {
        self.createTileServerView = [[MCNewTileServerViewController alloc] init];
        self.createTileServerView.saveTileServerDelegate = self;
        self.createTileServerView.modalPresentationStyle = UIModalPresentationPageSheet;
        [self.settingsViewController presentViewController:self.createTileServerView animated:YES completion:nil];
        [self.createTileServerView setServerName:serverName];
        [self.createTileServerView setServerURL:[serverUrls objectForKey:serverName]];
    }
}


- (void)deleteTileServer:(nonnull MCTileServer *)tileServer {
    [[MCTileServerRepository shared] removeTileServerFromUserDefaultsWithServerName:tileServer.serverName];
    NSError *keychainError = nil;
    [[MCKeychainUtil shared] deleteCredentialsWithServer:tileServer.url error:&keychainError];
    // TODO: Handle keychain error
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
