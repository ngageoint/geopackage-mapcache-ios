//
//  GPKGSCoordinator.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/31/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPKGGeoPackageManager.h>
#import <GPKGTileBoundingBoxUtils.h>
#import <GPKGTileGrid.h>
#import "PROJProjectionFactory.h"
#import "MCLoadTilesTask.h"
#import "MCGeopackageSingleViewController.h"
#import "MCDatabase.h"
#import "MCDatabases.h"
#import "GPKGSCreateTilesData.h"
#import "GPKGSLoadTilesData.h"
#import "GPKGSGenerateTilesData.h"
#import "GPKGSLoadTilesProtocol.h"
#import "MCCreateLayerViewController.h"
#import "MCFeatureLayerDetailsViewController.h"
#import "MCTileLayerDetailsViewController.h"
#import "MCBoundingBoxGuideView.h"
#import "MCZoomAndQualityViewController.h"
#import "MCFeatureLayerOperationsCell.h"
#import "MCMapCoordinator.h"
#import "MCTileServerHelpViewController.h"
#import "MCSettingsCoordinator.h"
#import "MCTileServerURLManagerViewController.h"
#import "MCFeatureLayerDetailsViewController.h"
#import "MCGeoPackageRepository.h"
#import "WMSTileOverlay.h"
#import "MCLayerSelectViewController.h"


@class MCTileServer;
@class MCLayer;

@protocol MCMapDelegate;
@protocol MCLayerCoordinatorDelegate;
@protocol MCGeoPackageCoordinatorDelegate <NSObject>
- (void) geoPackageCoordinatorCompletionHandlerForDatabase:(NSString *) database withDelete:(BOOL)didDelete;
@end

@interface MCGeoPackageCoordinator: NSObject <MCOperationsDelegate, MCFeatureLayerCreationDelegate, MCTileLayerDetailsDelegate, MCBoundingBoxGuideDelegate, MCZoomAndQualityDelegate, GPKGSLoadTilesProtocol, MCSelectTileServerDelegate, MCFeatureLayerCreationDelegate, MCLayerCoordinatorDelegate, MCLayerSelectDelegate>
- (instancetype) initWithDelegate:(id<MCGeoPackageCoordinatorDelegate>)geoPackageCoordinatorDelegate andDrawerDelegate:(id<NGADrawerViewDelegate>) drawerDelegate andMapDelegate:(id<MCMapDelegate>) mapDelegate andDatabase:(MCDatabase *) database;
- (void) start;
@end
