//
//  MCSettingsCoordinator.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/5/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCSettingsViewController.h"


@interface MCSettingsCoordinator : NSObject 
@property (nonatomic, strong) id<NGADrawerViewDelegate> drawerViewDelegate;
@property (nonatomic, strong) id<MCSettingsViewDelegate> settingsDelegate;
- (void)start;
@end
