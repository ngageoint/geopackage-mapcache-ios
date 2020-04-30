//
//  MCMapPointDataViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 4/16/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "NGADrawerViewController.h"
#import "MCFieldWithTitleCell.h"
#import "MCButtonCell.h"
#import "MCTitleCell.h"
#import "MCDescriptionCell.h"
#import "MCDualButtonCell.h"
#import "MCTextViewCell.h"
#import "MCKeyValueDisplayCell.h"
#import "GPKGMapUtils.h"
#import "GPKGUserRow.h"

NS_ASSUME_NONNULL_BEGIN

@protocol MCMapPointDataDelegate <NSObject>
- (BOOL)saveRow:(GPKGUserRow *)row;
@end

@interface MCMapPointDataViewController : NGADrawerViewController <UITableViewDataSource, UITableViewDelegate, MCDualButtonCellDelegate, MCButtonCellDelegate>
@property (nonatomic, strong) id<MCMapPointDataDelegate>mapPointDataDelegate;
@property (nonatomic, strong) GPKGMapPoint *mapPoint;
@property (nonatomic) BOOL isInEditMode;
- (instancetype) initWithMapPoint:(GPKGMapPoint *)mapPoint row:(GPKGUserRow *)row asFullView:(BOOL)fullView drawerDelegate:(id<NGADrawerViewDelegate>) drawerDelegate pointDataDelegate:(id<MCMapPointDataDelegate>) pointDataDelegate;
@end

NS_ASSUME_NONNULL_END
