//
//  MCZoomAndQualityViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/7/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCSectionTitleCell.h"
#import "MCFieldWithTitleCell.h"
#import "MCSegmentedControlCell.h"
#import "MCButtonCell.h"
#import "MCZoomCell.h"
#import "MCDescriptionCell.h"
#import "NGADrawerViewController.h"


@protocol MCZoomAndQualityDelegate
- (void) zoomAndQualityCompletionHandlerWith:(NSString *)layerName andMinZoom:(NSNumber *) minZoom andMaxZoom:(NSNumber *) maxZoom;
- (void) goBackToBoundingBox;
- (void) cancelZoomAndQuality;
- (NSString *) updateTileDownloadSizeEstimateWith:(NSNumber *) minZoom andMaxZoom:(NSNumber *) maxZoom;
- (BOOL) isLayerNameAvailable: (NSString *) layerName;
@end

@interface MCZoomAndQualityViewController : NGADrawerViewController <MCButtonCellDelegate, MCZoomCellValueChangedDelegate, UITextFieldDelegate>
@property (weak, nonatomic) id<MCZoomAndQualityDelegate> zoomAndQualityDelegate;
@end
