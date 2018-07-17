//
//  MCManualBoundingBoxViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/23/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCSectionTitleCell.h"
#import "MCFieldWithTitleCell.h"
#import "MCDesctiptionCell.h"
#import "MCButtonCell.h"
#import "GPKGBoundingBox.h"

@protocol MCManualBoundingBoxDelegate
- (void)manualBoundingBoxCompletionHandlerWithLowerLeftLat:(double)lowerLeftLat andLowerLeftLon:(double)lowerLeftLon andUpperRightLat:(double)upperRightLat andUpperRightLon:(double)upperRightLon;
@end


@interface MCManualBoundingBoxViewController : UITableViewController <UITextFieldDelegate, GPKGSButtonCellDelegate>
@property (weak, nonatomic) id<MCManualBoundingBoxDelegate> delegate;
- (instancetype) initWithLowerLeftLat:(double)lowerLeftLat andLowerLeftLon:(double)lowerLeftLon andUpperRightLat:(double)upperRightLat andUpperRightLon:(double)upperRightLon;
@end
