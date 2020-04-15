//
//  MCMapCoordinator.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 9/12/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCMapCoordinator.h"
#import "MCMapViewController.h"


NSString * const MC_MAP_TYPE_PREFERENCE = @"mapTyper";
NSString * const MC_MAX_FEATURES_PREFERENCE = @"maxFeatures";

@interface MCMapCoordinator ()
@property (nonatomic, strong) MCMapViewController *mcMapViewController;
@property (nonatomic, strong) UIView *boundingBoxGuideView;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) NSMutableArray *childCoordinators;
@property (nonatomic, strong) NSUserDefaults *preferences;
@property (nonatomic, strong) MCDrawingStatusViewController *drawingStatusViewController;
@property (nonatomic, strong) MCFeatureLayerDetailsViewController *featureLayerDetailsView;
@property (nonatomic, strong) MCGeoPackageRepository *repository;
@end


@implementation MCMapCoordinator

- (instancetype) initWithMapViewController:(MCMapViewController *) mapViewController {
    self = [super init];
    self.mcMapViewController = mapViewController;
    self.mcMapViewController.mapActionDelegate = self;
    self.manager = [GPKGGeoPackageFactory manager];
    self.childCoordinators = [[NSMutableArray alloc] init];
    self.preferences = [NSUserDefaults standardUserDefaults];
    self.repository = [MCGeoPackageRepository sharedRepository];
    
    return self;
}


- (void) loadPreferences {
    
    [self.preferences stringForKey:MC_MAP_TYPE_PREFERENCE];
    [self.preferences integerForKey:MC_MAX_FEATURES_PREFERENCE];
    // check for a map prefenrence, if there isnt one, use the standard map
    // check for max features, if there isnt a value go with 5000
    
}


- (void) setMapTypePreference {
    
}


- (void) setMaxFeaturesPreference {
    
}


#pragma mark - MCMapDelegate methods
- (void) updateMapLayers {
    NSLog(@"In MapCoordinator, going to update layers");
    [self.mcMapViewController updateInBackgroundWithZoom:NO];
}


- (void) toggleGeoPackage:(MCDatabase *) geoPackage {
    NSLog(@"In MCMapCoordinator, going to toggle %@", geoPackage.name);
}


- (void)zoomToSelectedGeoPackage:(NSString *)geoPackageName {
    GPKGGeoPackage *geoPackage = [self.manager open:geoPackageName];
    GPKGBoundingBox *boundingBox = [geoPackage contentsBoundingBoxInProjection:[SFPProjectionFactory projectionWithEpsgInt:PROJ_EPSG_WORLD_GEODETIC_SYSTEM]];
    CLLocationCoordinate2D center = [boundingBox center];
    
    if (center.latitude != 0 && center.longitude != 0) {
        [self.mcMapViewController zoomToPointWithOffset:center];
    }
    
    [geoPackage close];
}


- (void) setupTileBoundingBoxGuide:(UIView *) boudingBoxGuideView {
    self.boundingBoxGuideView = boudingBoxGuideView;
    self.boundingBoxGuideView.alpha = 0.0;
    [self.mcMapViewController.view addSubview:self.boundingBoxGuideView];
    
    [UIView animateWithDuration:0.35 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.boundingBoxGuideView.alpha = 1.0;
    } completion:nil];
    
    [self.mcMapViewController toggleMapControls];
}


- (void) removeTileBoundingBoxGuide {
    if  (self.boundingBoxGuideView != nil) {
        
        [UIView animateWithDuration:0.35 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.boundingBoxGuideView.alpha = 0.0;
        } completion:^(BOOL finished) {
            [self.boundingBoxGuideView removeFromSuperview];
            [self.mcMapViewController toggleMapControls];
        }];
    }
}


- (CLLocationCoordinate2D) convertPointToCoordinate:(CGPoint) point {
    return [self.mcMapViewController convertPointToCoordinate:point];
}


#pragma mark - MCMapActionDelegate
- (void)showMapInfoDrawer {
    MCSettingsCoordinator *settingsCoordinator = [[MCSettingsCoordinator alloc] init];
    [self.childCoordinators addObject:settingsCoordinator];
    settingsCoordinator.drawerViewDelegate = _drawerViewDelegate;
    settingsCoordinator.settingsDelegate = _mcMapViewController;
    [settingsCoordinator start];
}


- (void)showDrawingTools {
    _drawingStatusViewController = [[MCDrawingStatusViewController alloc] init];
    _drawingStatusViewController.drawerViewDelegate = _drawerViewDelegate;
    _drawingStatusViewController.drawingStatusDelegate = self;
    _drawingStatusViewController.databases = [_repository databaseList];
    [_drawerViewDelegate pushDrawer:_drawingStatusViewController];
}


#pragma mark - MCDrawingStatusDelegate methods
- (BOOL)savePointsToDatabase:(MCDatabase *)database andTable:(MCTable *) table {
    if (self.mcMapViewController.tempMapPoints && self.mcMapViewController.tempMapPoints.count > 0) {
        if ([_repository savePoints:self.mcMapViewController.tempMapPoints toDatabase:database table:table]) {
            [_mcMapViewController setDrawing:NO];
            [_mcMapViewController clearTempPoints];
            [self updateMapLayers];
            [[NSNotificationCenter defaultCenter] postNotificationName:MC_GEOPACKAGE_MODIFIED_NOTIFICATION object:self];
            return YES;
        }
    }
    
    return NO;
}


- (void)showNewGeoPacakgeView {
    MCCreateGeoPacakgeViewController *createGeoPackageView = [[MCCreateGeoPacakgeViewController alloc] initAsFullView:YES];
    createGeoPackageView.drawerViewDelegate = self.drawerViewDelegate;
    createGeoPackageView.createGeoPackageDelegate = self;
    [createGeoPackageView.drawerViewDelegate pushDrawer:createGeoPackageView];
}


- (void)showNewLayerViewWithDatabase:(MCDatabase *)database {
    _featureLayerDetailsView = [[MCFeatureLayerDetailsViewController alloc] initAsFullView:YES];
    _featureLayerDetailsView.delegate = self;
    _featureLayerDetailsView.drawerViewDelegate = _drawerViewDelegate;
    _featureLayerDetailsView.database = database;
    [_drawerViewDelegate pushDrawer:_featureLayerDetailsView];
    
}


- (void)updateDrawingStatus {
    [_drawingStatusViewController updateStatusLabelWithString:[NSString stringWithFormat:@"%d new points", (int)self.mcMapViewController.tempMapPoints.count]];
}


- (void)cancelDrawingFeatures {
    [_mcMapViewController setDrawing:NO];
    [_mcMapViewController clearTempPoints];
    [[NSNotificationCenter defaultCenter] postNotificationName:MC_GEOPACKAGE_MODIFIED_NOTIFICATION object:self];
}


#pragma mark - MCFeatureLayerCreationDelegate methods
- (void) createFeatueLayerIn:(NSString *)database withGeomertyColumns:(GPKGGeometryColumns *)geometryColumns andBoundingBox:(GPKGBoundingBox *)boundingBox andSrsId:(NSNumber *) srsId {
    NSLog(@"creating layer %@ in database %@ ", geometryColumns.tableName, database);

    BOOL didCreateLayer = [_repository createFeatueLayerIn:database withGeomertyColumns:geometryColumns boundingBox:boundingBox srsId:srsId];
    if (didCreateLayer) {
        [_drawerViewDelegate popDrawer];
        [_repository regenerateDatabaseList];
        _drawingStatusViewController.selectedGeoPackage = [_repository databseNamed:database];
        [_drawingStatusViewController showLayerSelectionMode];
    } else {
        //TODO handle the case where a new feature layer could not be created
    }
}


#pragma mark - MCCreateGeoPackageDelegate methods
- (BOOL) isValidGeoPackageName:(NSString *) name {
    NSArray *databaseNames = [self.manager databases];
    
    if ([name isEqualToString: @""]) {
        return NO;
    }
    
    for (NSString * databaseName in databaseNames) {
        if ([name isEqualToString:databaseName]) {
            return NO;
        }
    }
    
    return YES;
}


- (void) createGeoPackage:(NSString *) geoPackageName {
    NSLog(@"Creating GeoPackage %@", geoPackageName);
    [_repository createGeoPackage:geoPackageName];
    [_repository regenerateDatabaseList];
    [_drawingStatusViewController refreshViewWithNewGeoPackageList:[_repository databaseList]];
}



-(CLLocationCoordinate2D *) getPolygonPointsWithPoint1: (CLLocationCoordinate2D) point1 andPoint2: (CLLocationCoordinate2D) point2{
    CLLocationCoordinate2D *coordinates = calloc(4, sizeof(CLLocationCoordinate2D));
    coordinates[0] = CLLocationCoordinate2DMake(point1.latitude, point1.longitude);
    coordinates[1] = CLLocationCoordinate2DMake(point1.latitude, point2.longitude);
    coordinates[2] = CLLocationCoordinate2DMake(point2.latitude, point2.longitude);
    coordinates[3] = CLLocationCoordinate2DMake(point2.latitude, point1.longitude);
    return coordinates;
}


@end
