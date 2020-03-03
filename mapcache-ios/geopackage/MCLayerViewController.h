//
//  MCLayerViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 7/3/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGUserDao.h"
#import "GPKGFeatureDao.h"
#import "GPKGTileDao.h"
#import "MCFeatureTable.h"
#import "MCTileTable.h"
#import "MCButtonCell.h"
#import "MCSectionTitleCell.h"
#import "MCHeaderCell.h"
#import "MCUtils.h"
#import "MCProperties.h"
#import <GPKGGeoPackageManager.h>
#import <SFPProjectionTransform.h>
#import "MCFeatureLayerOperationsCell.h"
#import "MCTileLayerOperationsCell.h"
#import "SFPProjectionConstants.h"
#import "GPKGOverlayFactory.h"

@protocol MCLayerOperationsDelegate <NSObject>
- (void) deleteLayer;
- (void) createOverlay;
- (void) indexLayer;
- (void) createTiles;
- (void) renameLayer:(NSString *) layerName;
- (void) showTileScalingOptions;
@end


@interface MCLayerViewController : UITableViewController <MCFeatureLayerOperationsCellDelegate, MCTileLayerOperationsCellDelegate>
@property (strong, nonatomic) GPKGUserDao *layerDao;
@property (weak, nonatomic) id<MCLayerOperationsDelegate> delegate;
@end
