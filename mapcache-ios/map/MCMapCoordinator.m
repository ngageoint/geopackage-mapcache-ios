//
//  MCMapCoordinator.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 9/12/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCMapCoordinator.h"
#import "MCMapViewController.h"
#import "mapcache_ios-Swift.h"

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
@property (nonatomic, strong) MCMapPointAttachmentViewController *attachmentView;
@property (nonatomic, strong) MCGeoPackageRepository *repository;
@property (nonatomic, strong) GPKGMapPoint *mapPoint;
@property (nonatomic, strong) GPKGMediaRow *selectedAttachment; // If the attachment was saved
@property (nonatomic, strong) NSNumber *selectedAttachmentIndex; // if the attachment has been selected while editing the feature, but hasn't been saved
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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(basemapsLoadedFromUserDefaults:) name:MC_USER_BASEMAP_LOADED_FROM_DEFAULTS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(layerRenamed:) name:@"MC_LAYER_RENAMED" object:nil];
    
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


- (void)basemapsLoadedFromUserDefaults:(NSNotification *)notification {
    MCTileServer *basemapTileServer = [[MCTileServerRepository shared] baseMapServer];
    
    if (basemapTileServer == nil) {
        return;
    }
    
    if (basemapTileServer.serverType == MCTileServerTypeXyz) {
        @try {
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self.mcMapViewController updateBasemaps:basemapTileServer.url serverType:MCTileServerTypeXyz];
            });
        } @catch(NSException *e) {
            NSLog(@"Tile error");
        }
    } else if (basemapTileServer.serverType == MCTileServerTypeWms) {
        MCLayer *basemapLayer = [[MCTileServerRepository shared] baseMapLayer];
        
        if (basemapLayer == nil) {
            return;
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.mcMapViewController updateBasemaps: [basemapTileServer urlForLayerWithLayer:basemapLayer boundingBoxTemplate:NO] serverType:MCTileServerTypeWms];
        });
    }
}


- (void)layerRenamed:(NSNotification *)notification {
    [self updateMapLayers];
}


#pragma mark - MCMapDelegate methods
/**
    Update the data on the map.
 */
- (void) updateMapLayers {
    NSLog(@"In MapCoordinator, going to update layers");
    self.mcMapViewController.active = [_repository activeDatabases];
    [self.mcMapViewController updateInBackgroundWithZoom:NO andFilter:YES];
}


- (void) toggleGeoPackage:(MCDatabase *) geoPackage {
    NSLog(@"In MCMapCoordinator, going to toggle %@", geoPackage.name);
}


/**
    React to a GeoPackage being selected from the list. Set the map region to have the selected GeoPackage in view.
 */
- (void)zoomToSelectedGeoPackage:(NSString *)geoPackageName {
    GPKGGeoPackage *geoPackage = nil;
    
    @try {
        geoPackage = [self.manager open:geoPackageName];
        GPKGBoundingBox *boundingBox = [geoPackage contentsBoundingBoxInProjection:[PROJProjectionFactory projectionWithEpsgInt:PROJ_EPSG_WORLD_GEODETIC_SYSTEM]];
        CLLocationCoordinate2D center = [boundingBox center];
        
        if (center.latitude != 0 && center.longitude != 0) {
            [self.mcMapViewController zoomToPointWithOffset:center];
        }
    } @catch (NSException *e) {
        NSLog(@"MCMapCoordinator - Problem zooming to geopacakge\n%@", e.reason);
    } @finally {
        if (geoPackage != nil) {
            [geoPackage close];
        }
    }
}


/**
    React to a GeoPackage being selected from the list. Set the map region to have the selected GeoPackage in view.
 */
- (void)zoomToPoint:(CLLocationCoordinate2D)point withZoomLevel:(NSUInteger) zoomLevel {
    if (point.latitude != 0 && point.longitude != 0) {
        @try {
            [self.mcMapViewController zoomToPointWithOffset:point zoomLevel:zoomLevel];
        } @catch (NSException *e) {
            NSLog(@"MCMapCoordinator - Problem zooming to point\n%@", e.reason);
        }
    }
}


/**
    Get the map view ready to select an area where you would like to download tiles.
 */
- (void) setupTileBoundingBoxGuide:(UIView *) boudingBoxGuideView tileUrl:(NSString *)tileUrl serverType:(MCTileServerType) serverType {
    self.boundingBoxGuideView = boudingBoxGuideView;
    self.boundingBoxGuideView.alpha = 0.0;
    [self.mcMapViewController.view insertSubview:self.boundingBoxGuideView belowSubview:self.mcMapViewController.zoomIndicatorButton];
    
    [UIView animateWithDuration:0.35 delay:0.0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        self.boundingBoxGuideView.alpha = 1.0;
    } completion:nil];
    
    [self.mcMapViewController toggleMapControls];
    [self.mcMapViewController updateBasemaps:@"" serverType:MCTileServerTypeError];
    [self.mcMapViewController addUserTilesWithUrl:tileUrl serverType:serverType];
    self.mcMapViewController.boundingBoxMode = YES;
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
            self.mcMapViewController.boundingBoxMode = NO;
        }];
    }
}


/**
    Used for preview tiles when downloading a map or choosing a saved server as a basemap.
 */
- (void)addTileOverlay:(NSString *)tileServerURL serverType:(MCTileServerType)serverType username:(NSString *)username password:(NSString *)password {
    [self.mcMapViewController addUserTilesWithUrl:tileServerURL serverType:serverType];
    
    if (serverType == MCTileServerTypeXyz) {
        MKTileOverlay *tileOverlay = [[MKTileOverlay alloc] initWithURLTemplate:tileServerURL];
        [self.mcMapViewController addUserTileOverlay:tileOverlay];
    } else if (serverType == MCTileServerTypeWms) {
        WMSTileOverlay *wmsTileOverlay = [[WMSTileOverlay alloc] initWithURL:tileServerURL username:username password:password];
        [self.mcMapViewController addUserTileOverlay:wmsTileOverlay];
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
    settingsCoordinator.presentingViewController = self.mcMapViewController;
    settingsCoordinator.drawerViewDelegate = _drawerViewDelegate;
    settingsCoordinator.settingsDelegate = _mcMapViewController;
    [settingsCoordinator start];
}


/**
    Update the status label on the drawing tools view. This will show the number of points that will be added.
 */
- (void)updateDrawingStatus {
    [_drawingStatusViewController updateStatusLabelWithString:[NSString stringWithFormat:@"%d new points", (int)self.mcMapViewController.tempMapPoints.count]];
}


/**
    A map point was pressed, Query the GeoPackage's feature table for that row and show the details view. By default there are two columns, id and geom. If there are additional columns they will be shown in this view.
    If the drawer was already displaying data from another point, pass the data to the drawer and it will reload and update.
 */
- (void)showDetailsForAnnotation:(GPKGMapPoint *)mapPoint {
    if (mapPoint.data == nil) { // this is a new point
        // When you have selected a geopackage and a layer from the main list, when you longpress on the map we assume
        // that is where you would like to save the new point. If you have not selected anything, then you will be
        // presented with the existing geopackages and layers, or offered the ability to create a new one.
        
        self.mapPoint = mapPoint;
        NSString *selectedGeoPackage = _repository.selectedGeoPackageName;
        NSString *selectedLayer = _repository.selectedLayerName;
        
        // No GeoPackage or layer selected
        if (selectedGeoPackage == nil || [selectedGeoPackage isEqualToString:@""] || selectedLayer == nil || [selectedLayer isEqualToString:@""]) {
            _drawingStatusViewController = [[MCDrawingStatusViewController alloc] initAsFullView:YES];
            _drawingStatusViewController.drawerViewDelegate = _drawerViewDelegate;
            _drawingStatusViewController.drawingStatusDelegate = self;
            
            if (selectedGeoPackage == nil || [selectedGeoPackage isEqualToString:@""]) { // show the geopackage selection view
                _drawingStatusViewController.databases = [_repository databaseList];
                [_drawingStatusViewController pushOntoStack];
                [_drawingStatusViewController showGeoPackageSelectMode];
            } else if (selectedLayer == nil || [selectedLayer isEqualToString:@""]) { //show the layer selection view
                _drawingStatusViewController.selectedGeoPackage = [_repository databaseNamed:_repository.selectedGeoPackageName];
                [_drawingStatusViewController pushOntoStack];
                [_drawingStatusViewController showLayerSelectionMode];
            }
            
        } else { // Use the selected GeoPackage and layer to set the point data view
            GPKGFeatureRow *newRow = [_repository newRowInTable:selectedLayer database:selectedGeoPackage mapPoint:mapPoint];
            
            if (_mapPointDataViewController == nil) {                
                _mapPointDataViewController = [[MCMapPointDataViewController alloc] initWithMapPoint:mapPoint row:newRow databaseName:selectedGeoPackage layerName:selectedLayer media:[[NSMutableArray alloc] init] mode:MCPointViewModeEdit asFullView:YES drawerDelegate:_drawerViewDelegate pointDataDelegate:self showAttachmentDelegate:self];
                
                [_mapPointDataViewController pushOntoStack];
            } else {
                _mapPointDataViewController.databaseName = selectedGeoPackage;
                _mapPointDataViewController.layerName = selectedLayer;
                _mapPointDataViewController.media = [[NSMutableArray alloc] init];
                _mapPointDataViewController.mapPointDataDelegate = self;
                _mapPointDataViewController.showAttachmentDelegate = self;
                [_mapPointDataViewController reloadWith:newRow mapPoint:mapPoint mode:MCPointViewModeEdit];
            }
        }
    } else { // this is an existing point, query it's data and show it
        GPKGSMapPointData *pointData = (GPKGSMapPointData *)mapPoint.data;
        [_repository setSelectedGeoPackageName: pointData.database];
        [_repository setSelectedLayerName:pointData.tableName];
        GPKGUserRow *userRow = [_repository queryRow:pointData.featureId fromTableNamed:pointData.tableName inDatabase:pointData.database];
        NSArray *media = [[MCMediaUtility shared] mediaRelationsForGeoPackageName:pointData.database row:userRow];
        
        if (_mapPointDataViewController == nil) {
            _mapPointDataViewController = [[MCMapPointDataViewController alloc] initWithMapPoint:mapPoint row:userRow databaseName:_repository.selectedGeoPackageName layerName:_repository.selectedLayerName media:[NSMutableArray arrayWithArray: media] mode:MCPointViewModeDisplay asFullView:YES drawerDelegate:_drawerViewDelegate pointDataDelegate:self showAttachmentDelegate:self];
            [_drawerViewDelegate pushDrawer:_mapPointDataViewController];
        } else {
            _mapPointDataViewController.media = [[NSMutableArray alloc] initWithArray: media];
            _mapPointDataViewController.showAttachmentDelegate = self;
            [_mapPointDataViewController reloadWith:userRow mapPoint:mapPoint mode:MCPointViewModeDisplay];
        }
    }
}


- (void)showDrawingStatusViewController {
    
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
    [_repository setSelectedLayerName:@""];
    [_repository setSelectedGeoPackageName:@""];
    [[NSNotificationCenter defaultCenter] postNotificationName:MC_GEOPACKAGE_MODIFIED_NOTIFICATION object:self];
}


- (void)didSelectGeoPackage:(NSString *)geopackageName {
    [_repository setSelectedGeoPackageName:geopackageName];
}


- (void)didSelectLayer:(NSString *)layerName {
    [_repository setSelectedLayerName:layerName];
    // query and show the point data view
    
    [_drawingStatusViewController.drawerViewDelegate popDrawer];
    
    if (self.mapPoint != nil) {
        GPKGFeatureRow *newRow = [_repository newRowInTable:_repository.selectedLayerName database:_repository.selectedGeoPackageName mapPoint:self.mapPoint];
        _mapPointDataViewController = [[MCMapPointDataViewController alloc] initWithMapPoint:self.mapPoint row:newRow databaseName:_repository.selectedGeoPackageName layerName:_repository.selectedLayerName mode:MCPointViewModeEdit asFullView:YES drawerDelegate:_drawerViewDelegate pointDataDelegate:self];
        _mapPointDataViewController.showAttachmentDelegate = self;
        
        [_mapPointDataViewController pushOntoStack];
    }
}


#pragma mark - MCMapPointDataDelegate
/**
    Save the data from a map point, which is a row in a geopackage feature table.
 */
- (BOOL)saveRow:(GPKGUserRow *)row attachments:(nonnull NSArray *)media databaseName:(nonnull NSString *)databaseName{
    if([_repository saveRow:row]) {
        
        if (media.count > 0) {
            [MCMediaUtility.shared saveAttachmentsForRow:row media:media databaseName:databaseName];
            NSArray *media = [[MCMediaUtility shared] mediaRelationsForGeoPackageName:databaseName row:row];
            _mapPointDataViewController.media = [[NSMutableArray alloc] initWithArray: media];
            _mapPointDataViewController.showAttachmentDelegate = self;
        }
        
        [_mcMapViewController setDrawing:NO];
        [_mcMapViewController clearTempPoints];
        [self updateMapLayers];
        [[NSNotificationCenter defaultCenter] postNotificationName:MC_GEOPACKAGE_MODIFIED_NOTIFICATION object:self];
        return YES;
    }
    
    return NO;
}


/**
    Delete the row (map point) from the GeoPackage's feature table.
 */
- (int)deleteRow:(GPKGUserRow *)row fromDatabase:(NSString *)database andRemoveMapPoint:(nonnull GPKGMapPoint *)mapPoint {
    int rowsRemoved = [_repository deleteRow:row fromDatabase:database];
    
    if (rowsRemoved == 1) {
        [self.mcMapViewController removeMapPoint:mapPoint];
        [_mapPointDataViewController.drawerViewDelegate popDrawer];
        _mapPointDataViewController = nil;
    }
    
    return rowsRemoved;
}


/**
    The user has closed the map point details. Setting the drawer to nil cleans it up so a new drawer can be used next time a point is tapped.
 */
- (void)mapPointDataViewClosedWithNewPoint:(BOOL)didCloseWithNewPoint {
    [self.mcMapViewController.mapView deselectAnnotation:_mapPointDataViewController.mapPoint animated:YES];
    
    [_repository setSelectedLayerName:@""];
    [_repository setSelectedGeoPackageName:@""];
    
    if (didCloseWithNewPoint) {
        [_mcMapViewController setDrawing:NO];
        [_mcMapViewController clearTempPoints];
    }
    
    _mapPointDataViewController = nil;
}


- (void)showFieldEditor {
    MCDatabase *database = [_repository databaseNamed:_repository.selectedGeoPackageName];
    
    if (database != nil && [database hasTableNamed:_repository.selectedLayerName]) {
        MCTable *table = [database tableNamed:_repository.selectedLayerName];
        MCLayerCoordinator *layerCoordinator = [[MCLayerCoordinator alloc] initWithTable:table drawerDelegate:self.drawerViewDelegate layerCoordinatorDelegate:self launchedFromSingleLayerView:YES];
        [self.childCoordinators addObject:layerCoordinator];
        [layerCoordinator start];
    }
}


#pragma mark - MCShowAttachmentDelegate
- (void)showAttachmentWithMediaRow:(GPKGMediaRow *)mediaRow {
    self.attachmentView = [[MCMapPointAttachmentViewController alloc] initAsFullView:YES];
    self.selectedAttachment = mediaRow;
    self.selectedAttachmentIndex = [[NSNumber alloc] initWithInt:-1];
    self.attachmentView.image = [mediaRow dataImage];
    self.attachmentView.drawerViewDelegate = self.drawerViewDelegate;
    self.attachmentView.attachmentDelegate = self;
    [self.drawerViewDelegate pushDrawer:self.attachmentView];

}


- (void)showAttachmentWithImage:(UIImage *)image index:(NSNumber *)index {
    self.attachmentView = [[MCMapPointAttachmentViewController alloc] initAsFullView:YES];
    self.selectedAttachment = nil;
    self.selectedAttachmentIndex = index;
    self.attachmentView.image = image;
    self.attachmentView.drawerViewDelegate = self.drawerViewDelegate;
    self.attachmentView.attachmentDelegate = self;
    [self.drawerViewDelegate pushDrawer:self.attachmentView];
}


#pragma mark - MCPointAttachmentDelegate
- (void) deleteAttachment {
    NSLog(@"deleting attachment");
    
    if (self.selectedAttachmentIndex.integerValue > -1) {
        [_mapPointDataViewController.addedMedia removeObjectAtIndex:self.selectedAttachmentIndex.unsignedIntegerValue];
        [self.attachmentView closeDrawer];
        [_mapPointDataViewController reloadWith:_mapPointDataViewController.row mapPoint:_mapPoint mode:MCPointViewModeDisplay];
    } else {
        if ([MCMediaUtility.shared deleteAttachmentWithGeoPackageName:_repository.selectedGeoPackageName row:_mapPointDataViewController.row mediaRow:self.selectedAttachment]) {
            NSArray *media = [[MCMediaUtility shared] mediaRelationsForGeoPackageName:_repository.selectedGeoPackageName row:_mapPointDataViewController.row];
            _mapPointDataViewController.media = [[NSMutableArray alloc] initWithArray: media];
            [self.attachmentView closeDrawer];
            [_mapPointDataViewController reloadWith:_mapPointDataViewController.row mapPoint:_mapPoint mode:MCPointViewModeDisplay];
        } else {
            UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"Error" message:@"Unable to delete attachment." preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [errorAlert dismissViewControllerAnimated:YES completion:nil];
            }];
            [errorAlert addAction:okAction];
            [_attachmentView presentViewController:errorAlert animated:YES completion:nil];
        }
    }
}


#pragma mark - MCLayerCoordinatorDelegate methods
- (void)layerCoordinatorCompletionHandler {
    GPKGFeatureRow *newRow = [_repository newRowInTable:_repository.selectedLayerName database:_repository.selectedGeoPackageName mapPoint:self.mapPoint];
    self.mapPointDataViewController.row = newRow;
    [self.mapPointDataViewController reloadWith:newRow mapPoint:self.mapPoint mode:MCPointViewModeEdit];
    [self.childCoordinators removeLastObject];
    [self updateMapLayers];
    [self.geoPackageCoordinatorDelegate geoPackageCoordinatorCompletionHandlerForDatabase:_repository.selectedGeoPackageName withDelete:NO];
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
        _drawingStatusViewController.selectedGeoPackage = [_repository databaseNamed:database];
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
