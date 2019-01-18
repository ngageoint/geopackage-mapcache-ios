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


@interface MCSettingsCoordinator : NSObject <MCNoticeAndAttributeDelegate>
@property (nonatomic, strong) id<NGADrawerViewDelegate> drawerViewDelegate;
@property (nonatomic, strong) id<MCSettingsViewDelegate> settingsDelegate;
@property (nonatomic, strong) id<MCNoticeAndAttributeDelegate> noticeDelegate;
- (void)start;
@end
