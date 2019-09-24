//
//  GPKGSCoordinator.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/31/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPKGGeoPackageManager.h>
#import "GPKGSLoadTilesTask.h"
#import "MCGeopackageSingleViewController.h"
#import "GPKGSDatabase.h"
#import "GPKGSDatabases.h"
#import "GPKGSCreateTilesData.h"
#import "GPKGSLoadTilesData.h"
#import "GPKGSGenerateTilesData.h"
#import "GPKGSLoadTilesProtocol.h"
#import "MCCreateLayerViewController.h"
#import "MCFeatureLayerDetailsViewController.h"
#import "MCTileLayerDetailsViewController.h"
#import "MCBoundingBoxGuideView.h"
#import "MCZoomAndQualityViewController.h"
#import "MCManualBoundingBoxViewController.h"
#import "MCLayerViewController.h"
#import "GPKGSDisplayTextViewController.h"
#import "MCFeatureLayerOperationsCell.h"
#import "MCLayerCoordinator.h"
#import "MCMapCoordinator.h"


@protocol MCMapDelegate;
@protocol MCGeoPackageCoordinatorDelegate <NSObject>
- (void) geoPackageCoordinatorCompletionHandlerForDatabase:(NSString *) database withDelete:(BOOL)didDelete;
@end

@interface MCGeoPackageCoordinator: NSObject <MCOperationsDelegate, MCFeatureLayerCreationDelegate, MCTileLayerDetailsDelegate, MCBoundingBoxGuideDelegate, MCZoomAndQualityDelegate, MCCreateLayerDelegate, GPKGSLoadTilesProtocol>
- (instancetype) initWithDelegate:(id<MCGeoPackageCoordinatorDelegate>)geoPackageCoordinatorDelegate andDrawerDelegate:(id<NGADrawerViewDelegate>) drawerDelegate andMapDelegate:(id<MCMapDelegate>) mapDelegate andDatabase:(GPKGSDatabase *) database;
- (void) start;
@end
