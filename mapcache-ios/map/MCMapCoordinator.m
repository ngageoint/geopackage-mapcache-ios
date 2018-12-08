//
//  MCMapCoordinator.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 9/12/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCMapCoordinator.h"
#import "MCMapViewController.h"


@interface MCMapCoordinator ()
@property (nonatomic, strong) MCMapViewController *mcMapViewController;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) NSMutableArray *childCoordinators;
@end


@implementation MCMapCoordinator

- (instancetype) initWithMapViewController:(MCMapViewController *) mapViewController {
    self = [super init];
    self.mcMapViewController = mapViewController;
    self.mcMapViewController.mapActionDelegate = self;
    self.manager = [GPKGGeoPackageFactory getManager];
    self.childCoordinators = [[NSMutableArray alloc] init];
    
    return self;
}


#pragma mark - MCMapDelegate methods
- (void) updateMapLayers {
    NSLog(@"In MapCoordinator, going to update layers");
    [self.mcMapViewController updateInBackgroundWithZoom:NO];
}


- (void) toggleGeoPackage:(GPKGSDatabase *) geoPackage {
    NSLog(@"In MCMapCoordinator, going to toggle %@", geoPackage.name);
}


- (void)zoomToSelectedGeoPackage:(NSString *)geoPackageName {
    GPKGGeoPackage *geoPackage = [self.manager open:geoPackageName];
    GPKGBoundingBox *boundingBox = [geoPackage contentsBoundingBoxInProjection:[SFPProjectionFactory projectionWithEpsgInt:PROJ_EPSG_WORLD_GEODETIC_SYSTEM]];
    CLLocationCoordinate2D center = [boundingBox getCenter];
    
    [self.mcMapViewController zoomToPointWithOffset:center];
    [geoPackage close];
}


#pragma mark - MCMapActionDelegate
- (void)showMapInfoDrawer {
    MCSettingsCoordinator *settingsCoordinator = [[MCSettingsCoordinator alloc] init];
    [self.childCoordinators addObject:settingsCoordinator];
    settingsCoordinator.drawerViewDelegate = _drawerViewDelegate;
    settingsCoordinator.settingsDelegate = _mcMapViewController;
    [settingsCoordinator start];
}

@end
