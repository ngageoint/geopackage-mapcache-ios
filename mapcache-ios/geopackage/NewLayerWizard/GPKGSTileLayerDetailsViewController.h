//
//  GPKGSTileLayerDetailsViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/9/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSSectionTitleCell.h"
#import "GPKGSFieldWithTitleCell.h"
#import "GPKGSDesctiptionCell.h"
#import "GPKGSSectionTitleCell.h"
#import "GPKGSButtonCell.h"
#import "GPKGSSegmentedControlCell.h"
#import "GPKGSButtonCell.h"
#import "GPKGSColorUtil.h";

@protocol MCTileLayerDetailsDelegate
- (void) tileLayerDetailsCompletionHandler;
@end

@interface GPKGSTileLayerDetailsViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, GPKGSSegmentedControlCellDelegate, GPKGSButtonCellDelegate>
@property (weak, nonatomic) id<MCTileLayerDetailsDelegate> delegate;
@end
