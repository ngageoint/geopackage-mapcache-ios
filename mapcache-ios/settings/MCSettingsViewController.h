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
#import "MCDesctiptionCell.h"
#import "MCFieldWithTitleCell.h"
#import "MCButtonCell.h"
#import <MapKit/MapKit.h>

@protocol MCSettingsViewDelegate <NSObject>
- (void)setMapType:(NSString *) mapType;
@end


@protocol MCNoticeAndAttributeDelegate <NSObject>
- (void)showNoticeAndAttributeView;
@end


@interface MCSettingsViewController : NGADrawerViewController <UITableViewDelegate, UITableViewDataSource, MCSegmentedControlCellDelegate, GPKGSButtonCellDelegate>
@property (nonatomic, strong) id<MCSettingsViewDelegate> settingsDelegate;
@property (nonatomic, strong) id<MCNoticeAndAttributeDelegate>noticeAndAttributeDelegate;
@end
