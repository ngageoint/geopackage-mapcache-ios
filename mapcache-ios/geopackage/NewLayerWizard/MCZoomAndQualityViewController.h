//
//  MCZoomAndQualityViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/7/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSSectionTitleCell.h"
#import "GPKGSFieldWithTitleCell.h"
#import "GPKGSSegmentedControlCell.h"
#import "GPKGSButtonCell.h"

@protocol MCZoomAndQualityDelegate
- (void) zoomAndQualityCompletionHandlerWith:(NSNumber *) minZoom andMaxZoom:(NSNumber *) maxZoom;
@end

@interface MCZoomAndQualityViewController : UITableViewController <UITextFieldDelegate, GPKGSButtonCellDelegate>
@property (weak, nonatomic) id<MCZoomAndQualityDelegate> delegate;
@end
