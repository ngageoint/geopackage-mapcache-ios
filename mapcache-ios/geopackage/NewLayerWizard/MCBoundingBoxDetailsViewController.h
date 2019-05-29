//
//  MCBoundingBoxDetailsViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 12/9/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "NGADrawerViewController.h"
#import "MCButtonCell.h"
#import "MCDesctiptionCell.h"
#import "GPKGBoundingBox.h"

@protocol MCBoundingBoxDetailsViewDelegate <NSObject>
- (void) boundingBoxDetailsCompletionHandler:(GPKGBoundingBox *) boundingBox;
- (void) cancelBoundingBox;
@end

@interface MCBoundingBoxDetailsViewController : NGADrawerViewController <UITableViewDelegate, UITableViewDataSource, GPKGSButtonCellDelegate>
@property (nonatomic, strong) id<MCBoundingBoxDetailsViewDelegate> boundingBoxDetailsDelegate;
@end
