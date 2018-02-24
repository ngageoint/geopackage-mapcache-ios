//
//  MCManualBoundingBoxViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/23/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSSectionTitleCell.h"
#import "GPKGSFieldWithTitleCell.h"
#import "GPKGSButtonCell.h"
#import "GPKGBoundingBox.h"

@protocol MCManualBoundingBoxDelegate
- (void)manualBoundingBoxCompletionHandler:(GPKGBoundingBox *) boundingBox;
@end


@interface MCManualBoundingBoxViewController : UITableViewController <UITextFieldDelegate, GPKGSButtonCellDelegate>
@property (weak, nonatomic) id<MCManualBoundingBoxDelegate> delegate;
@end
