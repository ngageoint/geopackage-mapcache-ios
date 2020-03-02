//
//  MCDrawingStatusViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/20/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "NGADrawerViewController.h"
#import "MCButtonCell.h"
#import "MCDualButtonCell.h"
#import "MCDescriptionCell.h"
#import "MCTitleCell.h"
#import "MCGeoPackageCell.h"
#import "MCLayerCell.h"


NS_ASSUME_NONNULL_BEGIN


@protocol MCDrawingStatusDelegate <NSObject>
- (void)cancelDrawingFeatures;
- (void)showSaveLocationView;
@end


@interface MCDrawingStatusViewController : NGADrawerViewController <UITableViewDelegate, UITableViewDataSource, MCDualButtonCellDelegate>
@property (nonatomic, strong) id<MCDrawingStatusDelegate> drawingStatusDelegate;
@property (nonatomic, strong) NSArray *databases;
- (void)updateStatusLabelWithString:(NSString *) string;
@end

NS_ASSUME_NONNULL_END
