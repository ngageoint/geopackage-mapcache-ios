//
//  GPKGSCoordinator.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/31/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "MCGeoPackageCoordinator.h"
#import "mapcache_ios-Swift.h"


@interface MCGeoPackageCoordinator()
@property (nonatomic, strong) MCGeopackageSingleViewController *geoPackageViewController;
@property (nonatomic, strong) id<MCGeoPackageCoordinatorDelegate> geoPackageCoordinatorDelegate;
@property (nonatomic, strong) id<NGADrawerViewDelegate> drawerDelegate;
@property (nonatomic, strong) id<MCMapDelegate> mapDelegate;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) MCFeatureLayerDetailsViewController *featureDetailsController;
@property (nonatomic, strong) MCTileLayerDetailsViewController *tileDetailsController;
@property (nonatomic, strong) MCBoundingBoxGuideView *boundingBoxGuideViewController;
@property (nonatomic, strong) MCZoomAndQualityViewController *zoomAndQualityViewController;
@property (nonatomic, strong) MCFeatureLayerDetailsViewController *featureLayerDetailsView;
@property (nonatomic, strong) MCDatabases *active;
@property (nonatomic, strong) MCDatabase *database;
@property (nonatomic, strong) GPKGSCreateTilesData * tileData;
@property (nonatomic, strong) MCGeoPackageRepository *repository;
@property (nonatomic, strong) NSMutableArray *childCoordinators;
@end


@implementation MCGeoPackageCoordinator

- (instancetype) initWithDelegate:(id<MCGeoPackageCoordinatorDelegate>)geoPackageCoordinatorDelegate andDrawerDelegate:(id<NGADrawerViewDelegate>) drawerDelegate andMapDelegate:(id<MCMapDelegate>) mapDelegate andDatabase:(MCDatabase *) database {
    self = [super init];
    
    _childCoordinators = [[NSMutableArray alloc] init];
    _manager = [GPKGGeoPackageFactory manager];
    _repository = [MCGeoPackageRepository sharedRepository];
    _geoPackageCoordinatorDelegate = geoPackageCoordinatorDelegate;
    _drawerDelegate = drawerDelegate;
    _mapDelegate = mapDelegate;
    _database = database;
    _active = [MCDatabases getInstance];
    
    return self;
}


- (void) start {
    _geoPackageViewController = [[MCGeopackageSingleViewController alloc] initAsFullView:YES];
    
    _geoPackageViewController.database = _database;
    _geoPackageViewController.delegate = self;
    _geoPackageViewController.drawerViewDelegate = _drawerDelegate;
    [_drawerDelegate pushDrawer:_geoPackageViewController];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAndReload:) name:MC_GEOPACKAGE_MODIFIED_NOTIFICATION object:nil];
}


- (void)updateAndReload:(NSNotification *) notification {
    _database = [_repository refreshDatabaseAndUpdateList:_database.name];
    _geoPackageViewController.database = _database;
    [_geoPackageViewController update];
}


#pragma mark - GeoPackage View delegate methods
- (void) newTileLayer {
    NSLog(@"Coordinator handling new layer");
    NSLog(@"Adding new tile layer");
    _tileData = [[GPKGSCreateTilesData alloc] init];
    _tileDetailsController = [[MCTileLayerDetailsViewController alloc] initAsFullView:YES];
    _tileDetailsController.delegate = self;
    _tileDetailsController.drawerViewDelegate = _drawerDelegate;
    [_tileDetailsController.drawerViewDelegate pushDrawer:_tileDetailsController];
}


- (void) newFeatureLayer {
    _featureLayerDetailsView = [[MCFeatureLayerDetailsViewController alloc] initAsFullView:YES];
    _featureLayerDetailsView.delegate = self;
    _featureLayerDetailsView.drawerViewDelegate = _drawerDelegate;
    _featureLayerDetailsView.database = self.database;
    [_featureLayerDetailsView pushOntoStack];
}


- (void) updateDatabase {
    _database = [_repository refreshDatabaseAndUpdateList:self.database.name];
    self.geoPackageViewController.database = _database;
    [self.geoPackageViewController update];
}


- (void) copyGeoPackage {
    [_geoPackageCoordinatorDelegate geoPackageCoordinatorCompletionHandlerForDatabase:_database.name withDelete:NO];
}


- (void) deleteGeoPackage {
    NSLog(@"Coordinator handling delete");
    self.geoPackageViewController = nil;
    [_geoPackageCoordinatorDelegate geoPackageCoordinatorCompletionHandlerForDatabase:_database.name withDelete:YES];
}


- (void) callCompletionHandler {
    NSLog(@"Close pressed");
    [_geoPackageCoordinatorDelegate geoPackageCoordinatorCompletionHandlerForDatabase:_database.name withDelete:NO];
    [_repository setSelectedGeoPackageName:@""];
}


- (void) deleteLayer:(MCTable *) table {
    GPKGGeoPackage *geoPackage = nil;
    
    @try {
        geoPackage = [_manager open:_database.name];
        [geoPackage deleteTable:table.name];
        [_active removeTable:table];
        [_geoPackageViewController removeLayerNamed:table.name];
        [_mapDelegate updateMapLayers];
    }
    @catch (NSException *exception) {
        [MCUtils showMessageWithDelegate:self
                                   andTitle:[NSString stringWithFormat:@"%@ %@ - %@ Table", [MCProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_DELETE_LABEL], _database.name, table.name]
                                 andMessage:[NSString stringWithFormat:@"%@", [exception description]]];
    }
    @finally {
        [geoPackage close];
    }
}


- (void) toggleLayer:(MCTable *) table; {
    if ([_database exists:table]) {
        
        if ([_active isActive:_database]) {
            MCDatabase *activeDatabase = [_active getDatabaseWithName:_database.name];
            if ([activeDatabase existsWithTable:table.name ofType:table.getType]) {
                [_active removeTable:table];
            } else {
                [_active addTable:table];
            }
        } else {
            [_active addTable:table];
        }
        
        [_mapDelegate updateMapLayers];
    }
}


- (void) showLayerDetails:(MCTable *) table {
    NSLog(@"In showLayerDetails with %@", table.name);
    _repository.selectedLayerName = table.name;
    
    MCLayerCoordinator *layerCoordinator = [[MCLayerCoordinator alloc] initWithTable:table drawerDelegate:self.drawerDelegate layerCoordinatorDelegate:self];
    [self.childCoordinators addObject:layerCoordinator];
    
    [layerCoordinator start];
}


- (void) setSelectedDatabaseName {
    [self.repository setSelectedGeoPackageName:self.database.name];
}


#pragma mark - MCFeatureLayerCreationDelegate methods
/**
    Add a new feature layer to the GeoPackage.
 */
- (void) createFeatueLayerIn:(NSString *)database withGeomertyColumns:(GPKGGeometryColumns *)geometryColumns andBoundingBox:(GPKGBoundingBox *)boundingBox andSrsId:(NSNumber *) srsId {
    NSLog(@"creating layer %@ in database %@ ", geometryColumns.tableName, database);

    BOOL didCreateLayer = [_repository createFeatueLayerIn:database withGeomertyColumns:geometryColumns boundingBox:boundingBox srsId:srsId];
    if (didCreateLayer) {
        [_drawerDelegate popDrawer];
        _geoPackageViewController.database = [_repository refreshDatabaseAndUpdateList:_database.name];
        [_geoPackageViewController update];
    } else {
        //TODO handle the case where a new feature layer could not be created
    }
}


#pragma mark - MCLayerCoordinatorDelegate methods
- (void) layerCoordinatorCompletionHandler {
    // TODO update the geopackage view to reflect any changes
    _geoPackageViewController.database = [_repository databaseNamed:_database.name];
    [_geoPackageViewController update];
    [self.childCoordinators removeAllObjects];
}


#pragma mark - MCSelectTileServerDelegate
- (void) selectTileServer:(NSString *)serverURL {
    // pass the selected server url to the tile detail view controller to display in the url field
    NSLog(@"Selected %@", serverURL);
    _tileDetailsController.selectedServerURL = serverURL;
    [_tileDetailsController update];
}



#pragma mark - MCTileLayerDetailsDelegate
- (void) tileLayerDetailsCompletionHandlerWithName:(NSString *)name URL:(NSString *) url andReferenceSystemCode:(int)referenceCode {
    _tileData.name = name;
    _tileData.loadTiles.url = url;
    _tileData.loadTiles.epsg = referenceCode;
    
    [_drawerDelegate popDrawerAndHide];
    self.boundingBoxGuideViewController = [[MCBoundingBoxGuideView alloc] init];
    self.boundingBoxGuideViewController.delegate = self;
    [_mapDelegate setupTileBoundingBoxGuide: self.boundingBoxGuideViewController.view tileUrl:url];
}


- (void) showURLHelp {
    MCTileServerHelpViewController *tileHelpViewController = [[MCTileServerHelpViewController alloc] initAsFullView:YES];
    tileHelpViewController.drawerViewDelegate = _drawerDelegate;
    [tileHelpViewController.drawerViewDelegate pushDrawer:tileHelpViewController];
}


- (void) showTileServerList {
    MCSettingsCoordinator *settingsCoordinator = [[MCSettingsCoordinator alloc] init];
    [self.childCoordinators addObject:settingsCoordinator];
    settingsCoordinator.selectServerDelegate = self;
    settingsCoordinator.drawerViewDelegate = self.drawerDelegate;
    [settingsCoordinator startForServerSelection];
}


- (BOOL) isLayerNameAvailable: (NSString *) layerName {
    for (MCTable *table in [_database getTables]) {
        if ([layerName isEqualToString:table.name]){
            return NO;
        }
    }

    return YES;
}


#pragma mark MCBoundingBoxGuideDelegate methods
// TODO clean up these delegates, some duplicates in switching to the drawers from the navigation controller.
- (void) boundingBoxCompletionHandler:(CGRect) boundingBox {
    // make bounding box and hand it off accordingly
    
    
    CGPoint lowerLeft = CGPointMake(boundingBox.origin.x, boundingBox.origin.y + boundingBox.size.height);
    CGPoint upperRight = CGPointMake(boundingBox.origin.x + boundingBox.size.width, boundingBox.origin.y);
    
    CLLocationCoordinate2D lowerLeftCoordinate = [_mapDelegate convertPointToCoordinate:lowerLeft];
    CLLocationCoordinate2D upperRightCoordinate = [_mapDelegate convertPointToCoordinate:upperRight];
    
    GPKGBoundingBox *boundingBoxWithCoordinates = [[GPKGBoundingBox alloc] initWithMinLongitudeDouble:(double)lowerLeftCoordinate.longitude
                                                                             andMinLatitudeDouble:(double)lowerLeftCoordinate.latitude
                                                                            andMaxLongitudeDouble:(double)upperRightCoordinate.longitude
                                                                             andMaxLatitudeDouble:(double)upperRightCoordinate.latitude];
    
    
    _tileData.loadTiles.generateTiles.boundingBox = boundingBoxWithCoordinates;
    [_mapDelegate removeTileBoundingBoxGuide];
    
    _zoomAndQualityViewController = [[MCZoomAndQualityViewController alloc] initAsFullView:YES];
    _zoomAndQualityViewController.zoomAndQualityDelegate = self;
    _zoomAndQualityViewController.drawerViewDelegate = _drawerDelegate;
    [_zoomAndQualityViewController.drawerViewDelegate pushDrawer:_zoomAndQualityViewController];
}


- (void) boundingBoxCanceled {
    [self.mapDelegate removeTileBoundingBoxGuide];
    [self.mapDelegate updateMapLayers];
    [self.drawerDelegate showTopDrawer];
}


#pragma mark- MCZoomAndQualityDelegate methods
- (void) zoomAndQualityCompletionHandlerWith:(NSNumber *) minZoom andMaxZoom:(NSNumber *) maxZoom {
    NSLog(@"In wizard, going to call completion handler");
    
    _tileData.loadTiles.generateTiles.minZoom = minZoom;
    _tileData.loadTiles.generateTiles.maxZoom = maxZoom;
    [self createTileLayer:_tileData];
    [_mapDelegate updateMapLayers];
}


- (void) goBackToBoundingBox {
    [_drawerDelegate popDrawerAndHide];
    self.boundingBoxGuideViewController = [[MCBoundingBoxGuideView alloc] init];
    self.boundingBoxGuideViewController.delegate = self;
    [_mapDelegate setupTileBoundingBoxGuide: self.boundingBoxGuideViewController.view tileUrl:_tileData.loadTiles.url];
}

- (NSString *) updateTileDownloadSizeEstimateWith:(NSNumber *) minZoom andMaxZoom:(NSNumber *) maxZoom {
    int count = 0;
    GPKGBoundingBox *boundingBox = _tileData.loadTiles.generateTiles.boundingBox;
    
    SFPProjection *projection = [SFPProjectionFactory projectionWithAuthority: PROJ_AUTHORITY_EPSG andCode: [NSString stringWithFormat:@"%d", _tileData.loadTiles.epsg]];
    GPKGBoundingBox *transformedBox = boundingBox;
    
    if (![projection isEqualToAuthority:PROJ_AUTHORITY_EPSG andNumberCode:[NSNumber numberWithInt:PROJ_EPSG_WORLD_GEODETIC_SYSTEM]]) {
        GPKGBoundingBox *bounded = [GPKGTileBoundingBoxUtils boundWgs84BoundingBoxWithWebMercatorLimits:boundingBox];
        SFPProjectionTransform *transform = [[SFPProjectionTransform alloc] initWithFromEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM andToProjection:projection];
        transformedBox = [bounded transform:transform];
    }
    
    for (int zoom = [minZoom intValue]; zoom <= [maxZoom intValue]; zoom++) {
        GPKGTileGrid *tileGrid = [GPKGTileBoundingBoxUtils tileGridWithWebMercatorBoundingBox:transformedBox andZoom:zoom];
        count += [tileGrid count];
    }
    
    return [NSString stringWithFormat: @"Continue to donwload %d tiles for min zoom %@ and max zoom %@.", count, minZoom, maxZoom];
}


- (void) cancelZoomAndQuality {
    [self.mapDelegate updateMapLayers];
    [self updateDatabase];
}


#pragma mark - MCNewLayerWizardDelegate methods
- (void) createTileLayer:(GPKGSCreateTilesData *) tileData {
    NSLog(@"Coordinator attempting to create tiles");
    GPKGTileScaling *scaling = [MCLoadTilesTask tileScaling];
    
    @try {
        [MCLoadTilesTask loadTilesWithCallback:self
               andDatabase:_database.name
                  andTable:tileData.name
                    andUrl:tileData.loadTiles.url
                andMinZoom:[tileData.loadTiles.generateTiles.minZoom intValue]
                andMaxZoom:[tileData.loadTiles.generateTiles.maxZoom intValue]
         andCompressFormat:GPKG_CF_NONE // TODO: let user set this
        andCompressQuality:[[MCProperties getNumberValueOfProperty:GPKGS_PROP_LOAD_TILES_COMPRESS_QUALITY_DEFAULT] intValue]
          andCompressScale:100 // TODO: let user set this
               andXyzTiles:tileData.loadTiles.generateTiles.xyzTiles
            andBoundingBox:tileData.loadTiles.generateTiles.boundingBox
            andTileScaling:scaling
              andAuthority:PROJ_AUTHORITY_EPSG
                   andCode:[NSString stringWithFormat:@"%d",tileData.loadTiles.epsg]
                  andLabel:[MCProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_CREATE_TILES_LABEL]];
    } @catch(NSException *e) {
        NSLog(@"MCGeoPacakgeCoordinator - createTileLayer\n%@", e.reason);
    }
    
}


#pragma mark - GPKGSLoadTilesProtocol methods
-(void) onLoadTilesCanceled: (NSString *) result withCount: (int) count {
    //TODO: fill in
    NSLog(@"Loading tiles canceled");
}


-(void) onLoadTilesFailure: (NSString *) result withCount: (int) count {
    //TODO: fill in
    NSLog(@"Loading tiles failed");
    [_drawerDelegate popDrawer];
    [self updateDatabase];
}


-(void) onLoadTilesCompleted: (int) count {
    NSLog(@"Loading tiles completed");
    [_drawerDelegate popDrawer];
    [self updateDatabase];
}


@end
