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
#import "MCLayerCell.h"
#import "MCDatabase.h"
#import "MCDatabases.h"


NS_ASSUME_NONNULL_BEGIN


@protocol MCDrawingStatusDelegate <NSObject>
- (void)cancelDrawingFeatures;
- (void)showNewGeoPacakgeView;
- (void)showNewLayerViewWithDatabase:(MCDatabase*) database;
- (BOOL)savePointsToDatabase:(MCDatabase *)database andTable:(MCTable *) table;
@end


@interface MCDrawingStatusViewController : NGADrawerViewController <UITableViewDelegate, UITableViewDataSource, MCDualButtonCellDelegate>
@property (nonatomic, strong) id<MCDrawingStatusDelegate> drawingStatusDelegate;
@property (nonatomic, strong) NSArray *databases;
@property (nonatomic, strong) MCDatabase *selectedGeoPackage;
- (void)updateStatusLabelWithString:(NSString *) string;
- (void)refreshViewWithNewGeoPackageList:(NSArray *)databases;
- (void)showLayerSelectionMode;
@end

NS_ASSUME_NONNULL_END
