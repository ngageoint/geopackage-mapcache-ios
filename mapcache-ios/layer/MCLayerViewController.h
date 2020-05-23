//
//  MCLayerViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 7/3/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NGADrawerViewController.h"
#import "GPKGUserDao.h"
#import "GPKGFeatureDao.h"
#import "GPKGTileDao.h"
#import "MCFeatureTable.h"
#import "MCTileTable.h"
#import "MCButtonCell.h"
#import "MCSectionTitleCell.h"
#import "MCHeaderCell.h"
#import "MCLayerCell.h"
#import "MCUtils.h"
#import "MCProperties.h"
#import <GPKGGeoPackageManager.h>
#import <SFPProjectionTransform.h>
#import "MCFeatureLayerOperationsCell.h"
#import "MCTileLayerOperationsCell.h"
#import "MCDescriptionCell.h"
#import "MCTitleCell.h"
#import "SFPProjectionConstants.h"
#import "GPKGOverlayFactory.h"
#import "MCTable.h"
#import "MCTileTable.h"
#import "MCFeatureTable.h"


@protocol MCLayerOperationsDelegate <NSObject>
- (void) deleteLayer;
- (void) createOverlay;
- (void) indexLayer;
- (void) createTiles;
- (void) renameLayer:(NSString *) layerName;
- (void) showTileScalingOptions;
- (void) showFieldCreationView;
- (void) layerViewDidClose;
@end


@interface MCLayerViewController : NGADrawerViewController <UITableViewDelegate, UITableViewDataSource, MCFeatureLayerOperationsCellDelegate, MCTileLayerOperationsCellDelegate, MCButtonCellDelegate>
@property (strong, nonatomic) GPKGUserDao *layerDao;
@property (strong, nonatomic) MCTable* table;
@property (strong, nonatomic) NSArray *columns;
@property (weak, nonatomic) id<MCLayerOperationsDelegate> delegate;
@end
