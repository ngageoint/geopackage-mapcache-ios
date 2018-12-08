//
//  MCSettingsViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/5/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "NGADrawerViewController.h"
#import "MCTitleCell.h"
#import "MCSectionTitleCell.h"
#import "MCSegmentedControlCell.h"
#import "MCButtonCell.h"
#import <MapKit/MapKit.h>

@protocol MCSettingsViewDelegate <NSObject>
- (void)setMapType:(NSString *) mapType;
@end


@interface MCSettingsViewController : NGADrawerViewController <UITableViewDelegate, UITableViewDataSource, MCSegmentedControlCellDelegate>
@property (nonatomic, strong) id<MCSettingsViewDelegate> settingsDelegate;
@end
