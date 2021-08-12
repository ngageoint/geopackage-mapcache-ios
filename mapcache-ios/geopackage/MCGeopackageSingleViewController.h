//
//  GPKGSGeopackageSingleViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/31/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCTable.h"
#import "MCFeatureTable.h"
#import "MCTileTable.h"
#import "MCDatabase.h"
#import "MCDatabases.h"
#import "MCHeaderCell.h"
#import "MCSectionTitleCell.h"
#import "MCLayerCell.h"
#import "MCButtonCell.h"
#import "MCEmptyStateCell.h"
#import "MCConstants.h"
#import "MCProperties.h"
#import "MCGeoPackageOperationsCell.h"
#import <GPKGGeoPackageManager.h>
#import <GPKGGeoPackageFactory.h>
#import "MCUtils.h"
#import "NGADrawerViewController.h"


@protocol MCOperationsDelegate <NSObject>
- (void) newTileLayer;
- (void) newFeatureLayer;
- (void) deleteGeoPackage;
- (void) copyGeoPackage;
- (void) callCompletionHandler;
- (void) deleteLayer:(MCTable *) table;
- (void) showLayerDetails:(MCTable *) table;
- (void) toggleLayer:(MCTable *) table;
- (void) updateDatabase;
- (void) setSelectedDatabaseName;
@end


@interface MCGeopackageSingleViewController : NGADrawerViewController <UITableViewDataSource, UITableViewDelegate, MCButtonCellDelegate, MCGeoPackageOperationsCellDelegate>
@property (strong, nonatomic) MCDatabase *database;
@property (weak, nonatomic) id<MCOperationsDelegate> delegate;
- (void) update;
- (void) removeLayerNamed:(NSString *) layerName;
@end
