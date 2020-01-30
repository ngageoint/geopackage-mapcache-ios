//
//  MCSettingsCoordinator.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/5/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCSettingsViewController.h"
#import "MCNoticeAndAttributionViewController.h"
#import "MCTileServerURLManagerViewController.h"
#import "MCNewTileServerViewController.h"
#import "GPKGSConstants.h"


@interface MCSettingsCoordinator : NSObject <MCSettingsDelegate, MCTileServerManagerDelegate, MCSaveTileServerDelegate>
@property (nonatomic, strong) id<NGADrawerViewDelegate> drawerViewDelegate;
@property (nonatomic, strong) id<MCMapSettingsDelegate> settingsDelegate;
@property (nonatomic, strong) id<MCSettingsDelegate> noticeDelegate;
@property (nonatomic, strong) id<MCSelectTileServerDelegate> selectServerDelegate;
- (void)start;
- (void)startForServerSelection;
@end
