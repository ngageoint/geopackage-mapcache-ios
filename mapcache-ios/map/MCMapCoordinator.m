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
@property (nonatomic, strong) MCMapPointDataViewController *mapPointDataViewController;
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
/**
    Update the data on the map.
 */
- (void) updateMapLayers {
    NSLog(@"In MapCoordinator, going to update layers");
    [self.mcMapViewController updateInBackgroundWithZoom:NO andFilter:YES];
}


- (void) toggleGeoPackage:(MCDatabase *) geoPackage {
    NSLog(@"In MCMapCoordinator, going to toggle %@", geoPackage.name);
}


/**
    React to a GeoPackage being selected from the list. Set the map region to have the selected GeoPackage in view.
 */
- (void)zoomToSelectedGeoPackage:(NSString *)geoPackageName {
    GPKGGeoPackage *geoPackage = [self.manager open:geoPackageName];
    GPKGBoundingBox *boundingBox = [geoPackage contentsBoundingBoxInProjection:[SFPProjectionFactory projectionWithEpsgInt:PROJ_EPSG_WORLD_GEODETIC_SYSTEM]];
    CLLocationCoordinate2D center = [boundingBox center];
    
    if (center.latitude != 0 && center.longitude != 0) {
        [self.mcMapViewController zoomToPointWithOffset:center];
    }
    
    [geoPackage close];
}


/**
    Get the map view ready to select an area where you would like to download tiles.
 */
- (void) setupTileBoundingBoxGuide:(UIView *) boudingBoxGuideView {
    self.boundingBoxGuideView = boudingBoxGuideView;
    self.boundingBoxGuideView.alpha = 0.0;
    [self.mcMapViewController.view addSubview:self.boundingBoxGuideView];
    
    [UIView animateWithDuration:0.35 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.boundingBoxGuideView.alpha = 1.0;
    } completion:nil];
    
    [self.mcMapViewController toggleMapControls];
}


/**
    Clear the tile drawing bounding box and bring back the drawer and map controls.
 */
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
/**
    When the info button on the map is pressed show the info/settings drawer.
 */
- (void)showMapInfoDrawer {
    MCSettingsCoordinator *settingsCoordinator = [[MCSettingsCoordinator alloc] init];
    [self.childCoordinators addObject:settingsCoordinator];
    settingsCoordinator.drawerViewDelegate = _drawerViewDelegate;
    settingsCoordinator.settingsDelegate = _mcMapViewController;
    [settingsCoordinator start];
}


/**
    When the user long presses on the map, show the drawing tools.
 */
- (void)showDrawingTools {
    
    
    
    _drawingStatusViewController = [[MCDrawingStatusViewController alloc] init];
    _drawingStatusViewController.drawerViewDelegate = _drawerViewDelegate;
    _drawingStatusViewController.drawingStatusDelegate = self;
    _drawingStatusViewController.databases = [_repository databaseList];
    [_drawerViewDelegate pushDrawer:_drawingStatusViewController];
}


/**
    Update the status label on the drawing tools view. This will show the number of points that will be added.
 */
- (void)updateDrawingStatus {
    [_drawingStatusViewController updateStatusLabelWithString:[NSString stringWithFormat:@"%d new points", (int)self.mcMapViewController.tempMapPoints.count]];
}


/**
    A map point was pressed, Query the GeoPackage's feature table for that row and show the details view. By default there are two columns, id and geom. If threre are additional columns they will be shown in this view.
    If the drawer was already displaying data from another point, pass the data to the drawer and it will reload and update.
 */
- (void)showDetailsForAnnotation:(GPKGMapPoint *)mapPoint {
    GPKGSMapPointData *pointData = (GPKGSMapPointData *)mapPoint.data;
    GPKGUserRow *userRow = [_repository queryRow:pointData.featureId fromTableNamed:pointData.tableName inDatabase:pointData.database];
    
    if (_mapPointDataViewController == nil) {
        _mapPointDataViewController = [[MCMapPointDataViewController alloc] initWithMapPoint:mapPoint row:userRow asFullView:YES drawerDelegate:_drawerViewDelegate pointDataDelegate:self];
        [_drawerViewDelegate pushDrawer:_mapPointDataViewController];
    } else {
        [_mapPointDataViewController reloadWith:userRow mapPoint:mapPoint];
    }
}


#pragma mark - MCDrawingStatusDelegate methods
/**
    The user has long pressed and added one or more points to the map, and gone through the drawing status wizard that lets them choose where to save the points, ask the repository to save the points to the selected GeoPackage and table.
 */
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


/**
    Show the view that allows the user to create a new GeoPackage. This can happen from the map when the user has long pressed to create new points, and would like to save them to a new geopackage.
 */
- (void)showNewGeoPacakgeView {
    MCCreateGeoPacakgeViewController *createGeoPackageView = [[MCCreateGeoPacakgeViewController alloc] initAsFullView:YES];
    createGeoPackageView.drawerViewDelegate = self.drawerViewDelegate;
    createGeoPackageView.createGeoPackageDelegate = self;
    [createGeoPackageView.drawerViewDelegate pushDrawer:createGeoPackageView];
}


/**
    Show the new layer view. This can happen when the user is going to save new points and would like to save them to a new layer.
 */
- (void)showNewLayerViewWithDatabase:(MCDatabase *)database {
    _featureLayerDetailsView = [[MCFeatureLayerDetailsViewController alloc] initAsFullView:YES];
    _featureLayerDetailsView.delegate = self;
    _featureLayerDetailsView.drawerViewDelegate = _drawerViewDelegate;
    _featureLayerDetailsView.database = database;
    [_drawerViewDelegate pushDrawer:_featureLayerDetailsView];
    
}


/**
    Cancel adding new points. Clean up the map and remove the drawing status view.
 */
- (void)cancelDrawingFeatures {
    [_mcMapViewController setDrawing:NO];
    [_mcMapViewController clearTempPoints];
    [[NSNotificationCenter defaultCenter] postNotificationName:MC_GEOPACKAGE_MODIFIED_NOTIFICATION object:self];
}


#pragma mark - MCMapPointDataDelegate
/**
    Save the data from a map point, which is a row in a geopackage feature table.
 */
- (BOOL)saveRow:(GPKGUserRow *)row toDatabase:(NSString *)database{
    return [_repository saveRow:row toDatabase:database];
}


/**
    Delete the row (map point) from the GeoPackage's feature table.
 */
- (int)deleteRow:(GPKGUserRow *)row fromDatabase:(NSString *)database andRemoveMapPoint:(nonnull GPKGMapPoint *)mapPoint {
    int rowsRemoved = [_repository deleteRow:row fromDatabase:database];
    
    if (rowsRemoved == 1) {
        [self.mcMapViewController removeMapPoint:mapPoint];
    }
    
    return rowsRemoved;
}


/**
    The user has closed the map point details. Setting the drawer to nil cleans it up so a new drawer can be used next time a point is tapped.
 */
- (void)mapPointDataViewClosed {
    [self.mcMapViewController.mapView deselectAnnotation:_mapPointDataViewController.mapPoint animated:YES];
    _mapPointDataViewController = nil;
}


#pragma mark - MCFeatureLayerCreationDelegate methods
/**
    Add a new feature layer to the GeoPackage.
 */
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
/**
    When the user is creating a new GeoPackage check to make sure the name is not already in use or invalid.
 */
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


/**
    Create a new GeoPackage.
 */
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
