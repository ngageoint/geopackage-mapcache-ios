//
//  GPKGSGeopackageSingleViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/31/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSTable.h"
#import "GPKGSFeatureTable.h"
#import "GPKGSTileTable.h"
#import "GPKGSDatabase.h"
#import "GPKGSDatabases.h"
#import "MCHeaderCell.h"
#import "MCSectionTitleCell.h"
#import "MCLayerCell.h"
#import "MCButtonCell.h"
#import "GPKGSConstants.h"
#import "GPKGSProperties.h"
#import "MCGeoPackageOperationsCell.h"
#import <GPKGGeoPackageManager.h>
#import <GPKGGeoPackageFactory.h>
#import "GPKGSUtils.h"
#import "NGADrawerViewController.h"


@protocol MCOperationsDelegate <NSObject>
- (void) newLayer;
- (void) deleteGeoPackage;
- (void) copyGeoPackage;
- (void) callCompletionHandler;
- (void) deleteLayer:(GPKGSTable *) table;
- (void) showLayerDetails:(GPKGUserDao *) layerDao;
- (void) toggleLayer:(GPKGSTable *) table;
@end


@interface MCGeopackageSingleViewController : NGADrawerViewController <UITableViewDataSource, UITableViewDelegate, GPKGSButtonCellDelegate, MCGeoPackageOperationsCellDelegate>
@property (strong, nonatomic) GPKGSDatabase *database;
@property (weak, nonatomic) id<MCOperationsDelegate> delegate;
- (void) update;
- (void) removeLayerNamed:(NSString *) layerName;
@end
