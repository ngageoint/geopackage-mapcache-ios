//
//  MCMapCoordinator.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 9/12/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCGeoPackageListCoordinator.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGGeoPackageManager.h"
#import "MCSettingsCoordinator.h"
#import "MCBoundingBoxGuideView.h"
#import "MCDrawingStatusViewController.h"
#import "MCGeoPackageRepository.h"
#import "MCCreateGeoPacakgeViewController.h"
#import "MCFeatureLayerDetailsViewController.h"
#import "MCMapPointDataViewController.h"
#import "MCServerError.h"

// forward declarations
@class MCMapViewController;
@class MCTileServer;
@class MCLayer;
@class MCLayerCoordinator;
@class MCGeoPackageListCoordinator;
typedef NS_ENUM(NSInteger, MCTileServerType);
@protocol MCMapActionDelegate;
@protocol MCShowAttachmentDelegate;
@protocol MCPointAttachmentDelegate;
@protocol MCLayerCoordinatorDelegate;

@protocol MCMapDelegate <NSObject>
- (void) updateMapLayers;
- (void) toggleGeoPackage:(MCDatabase *) geoPackage;
- (void) zoomToSelectedGeoPackage:(NSString *) geoPackageName;
- (void) zoomToPoint:(CLLocationCoordinate2D)point withZoomLevel:(NSUInteger) zoomLevel;
- (void) setupTileBoundingBoxGuide:(UIView *) boudingBoxGuideView tileUrl:(NSString *)tileUrl serverType:(MCTileServerType) serverType;
- (void) removeTileBoundingBoxGuide;
- (void) addTileOverlay:(NSString *)tileServerURL serverType:(MCTileServerType)serverType username:(NSString *)username password:(NSString *)password;
- (CLLocationCoordinate2D) convertPointToCoordinate:(CGPoint) point;
@end


@interface MCMapCoordinator : NSObject <MCMapDelegate, MCMapActionDelegate, MCDrawingStatusDelegate, MCCreateGeoPackageDelegate, MCFeatureLayerCreationDelegate, MCMapPointDataDelegate, MCShowAttachmentDelegate, MCPointAttachmentDelegate, MCLayerCoordinatorDelegate>
- (instancetype) initWithMapViewController:(MCMapViewController *) mapViewController;
@property (nonatomic, strong) id<NGADrawerViewDelegate> drawerViewDelegate;
@property (nonatomic, strong) MCGeoPackageListCoordinator* geoPackageCoordinatorDelegate;
@end
