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
#import "GPKGSGeopackageSingleViewController.h"
#import "GPKGSDatabase.h"
#import "GPKGSLoadTilesProtocol.h"
#import "GPKGSCreateLayerViewController.h"
#import "GPKGSFeatureLayerDetailsViewController.h"
#import "GPKGSTileLayerDetailsViewController.h"
#import "MCBoundingBoxViewController.h"
#import "MCZoomAndQualityViewController.h"
#import "GPKGSCreateTilesData.h"
#import "GPKGSLoadTilesData.h"
#import "GPKGSGenerateTilesData.h"

@protocol GPKGSCoordinatorDelegate <NSObject>
- (void) geoPackageCoordinatorCompletionHandlerForDatabase:(NSString *) database withDelete:(BOOL)didDelete;
@end

@interface GPKGSCoordinator: NSObject <GPKGSOperationsDelegate, GPKGSFeatureLayerCreationDelegate, MCTileLayerDetailsDelegate, MCTileLayerBoundingBoxDelegate, MCZoomAndQualityDelegate, GPKGSCreateLayerDelegate, GPKGSLoadTilesProtocol>
- (instancetype) initWithNavigationController:(UINavigationController *) navigationController andDelegate:(id<GPKGSCoordinatorDelegate>)delegate andDatabase:(GPKGSDatabase *) database;
- (void) start;
@end
