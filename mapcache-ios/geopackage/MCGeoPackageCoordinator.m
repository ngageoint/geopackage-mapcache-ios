//
//  GPKGSCoordinator.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/31/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "MCGeoPackageCoordinator.h"


@interface MCGeoPackageCoordinator()
@property (nonatomic, strong) MCGeopackageSingleViewController *geoPackageViewController;
@property (nonatomic, strong) id<MCGeoPackageCoordinatorDelegate> geoPackageCoordinatorDelegate;
@property (nonatomic, strong) id<NGADrawerViewDelegate> drawerDelegate;
@property (nonatomic, strong) id<MCMapDelegate> mapDelegate;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) id<NGADrawerViewDelegate> drawerViewDelegate;
@property (nonatomic, strong) MCFeatureLayerDetailsViewController *featureDetailsController;
@property (nonatomic, strong) MCTileLayerDetailsViewController *tileDetailsController;
@property (nonatomic, strong) MCBoundingBoxGuideView *boundingBoxGuideViewController;
@property (nonatomic, strong) MCZoomAndQualityViewController *zoomAndQualityViewController;
@property (nonatomic, strong) MCDatabases *active;
@property (nonatomic, strong) MCDatabase *database;
@property (nonatomic, strong) GPKGSCreateTilesData * tileData;
@property (nonatomic, strong) NSMutableArray *childCoordinators;
@end


@implementation MCGeoPackageCoordinator

- (instancetype) initWithDelegate:(id<MCGeoPackageCoordinatorDelegate>)geoPackageCoordinatorDelegate andDrawerDelegate:(id<NGADrawerViewDelegate>) drawerDelegate andMapDelegate:(id<MCMapDelegate>) mapDelegate andDatabase:(MCDatabase *) database {
    self = [super init];
    
    _childCoordinators = [[NSMutableArray alloc] init];
    _manager = [GPKGGeoPackageFactory manager];
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
    
    //[_navigationController pushViewController:_geoPackageViewController animated:YES]; // TODO replace with drawer
}


#pragma mark - GeoPackage View delegate methods
- (void) newLayer {
    NSLog(@"Coordinator handling new layer");
    
    // Future release will bring feature and tile layers, for now starting with just the tiles.
//    MCCreateLayerViewController *createLayerViewControler = [[MCCreateLayerViewController alloc] initWithNibName:@"MCCreateLayerView" bundle:nil];
//    createLayerViewControler.delegate = self;
//    createLayerViewControler.drawerViewDelegate = _drawerDelegate;
//    [createLayerViewControler.drawerViewDelegate pushDrawer:createLayerViewControler];
    
    NSLog(@"Adding new tile layer");
    _tileData = [[GPKGSCreateTilesData alloc] init];
    _tileDetailsController = [[MCTileLayerDetailsViewController alloc] initAsFullView:YES];
    _tileDetailsController.delegate = self;
    _tileDetailsController.drawerViewDelegate = _drawerDelegate;
    [_tileDetailsController.drawerViewDelegate pushDrawer:_tileDetailsController];
}


- (void) updateDatabase {
    GPKGGeoPackage *geoPackage = nil;
    MCDatabase *updatedDatabase = nil;
    
    @try {
        geoPackage = [_manager open:_database.name];
        
        GPKGContentsDao *contentsDao = [geoPackage contentsDao];
        NSMutableArray *tables = [[NSMutableArray alloc] init];
        
        updatedDatabase = [[MCDatabase alloc] initWithName:_database.name andExpanded:false];
        
        // Handle the Feature Layers
        for (NSString *tableName in [geoPackage featureTables]) {
            GPKGFeatureDao *featureDao = [geoPackage featureDaoWithTableName:tableName];
            int count = [featureDao count];
            GPKGContents *contents = (GPKGContents *)[contentsDao queryForIdObject:tableName];
            GPKGGeometryColumns *geometryColumns = [contentsDao geometryColumns:contents];
            enum SFGeometryType geometryType = [SFGeometryTypes fromName:geometryColumns.geometryTypeName];
            MCFeatureTable *table = [[MCFeatureTable alloc] initWithDatabase:_database.name andName:tableName andGeometryType:geometryType andCount:count];
            
            [tables addObject:table];
            [updatedDatabase addFeature:table];
        }
        
        // Handle the tile layers
        for (NSString *tableName in [geoPackage tileTables]) {
            GPKGTileDao *tileDao = [geoPackage tileDaoWithTableName:tableName];
            int count = [tileDao count];
            
            MCTileTable *table = [[MCTileTable alloc] initWithDatabase:_database.name andName:tableName andCount:count andMinZoom:tileDao.minZoom andMaxZoom:tileDao.maxZoom];
            
            [tables addObject:table];
            [updatedDatabase addTile:table];
        }
        
        // TODO: Figure out what to do about overlays
    }
    @finally {
        if (geoPackage == nil) {
            @try {
                [_manager delete:_database.name];
            }
            @catch (NSException *exception) {
            }
        } else {
            if (updatedDatabase != nil) {
                _database = updatedDatabase;
                _geoPackageViewController.database = _database;
                [_geoPackageViewController update];
            }
            [geoPackage close];
        }
    }
}


- (void) copyGeoPackage {
    //[_navigationController popViewControllerAnimated:YES]; // TODO replace with drawer
    [_geoPackageCoordinatorDelegate geoPackageCoordinatorCompletionHandlerForDatabase:_database.name withDelete:NO];
}


- (void) deleteGeoPackage {
    NSLog(@"Coordinator handling delete");
    //[_navigationController popViewControllerAnimated:YES]; // TODO replace with drawer
    [_geoPackageCoordinatorDelegate geoPackageCoordinatorCompletionHandlerForDatabase:_database.name withDelete:YES];
}


- (void) callCompletionHandler {
    NSLog(@"Close pressed");
    [_geoPackageCoordinatorDelegate geoPackageCoordinatorCompletionHandlerForDatabase:_database.name withDelete:NO];
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


- (void) showLayerDetails:(GPKGUserDao *) layerDao {
    NSLog(@"In showLayerDetails with %@", layerDao.tableName);
    // TODO: Update to show the layerDetailsView in a drawer
}


#pragma mark - CreateLayerViewController delegate methods
- (void) newFeatureLayer {
    NSLog(@"Adding new feature layer");
    _featureDetailsController = [[MCFeatureLayerDetailsViewController alloc] init];
    _featureDetailsController.database = _database;
    _featureDetailsController.delegate = self;
    //[_navigationController pushViewController:_featureDetailsController animated:YES]; // TODO replace with drawer
}


// Temporarily moving this to new layer since initially they can only make tile layers.
- (void) newTileLayer {
    NSLog(@"Adding new tile layer");
    _tileData = [[GPKGSCreateTilesData alloc] init];
    _tileDetailsController = [[MCTileLayerDetailsViewController alloc] init];
    _tileDetailsController.delegate = self;
    _tileDetailsController.drawerViewDelegate = _drawerDelegate;
    // [_navigationController pushViewController:_tileDetailsController animated:YES]; // TODO replace with drawer
}


#pragma mark - GPKGSFeatureLayerCreationDelegate
- (void) createFeatueLayerIn:(NSString *)database with:(GPKGGeometryColumns *)geometryColumns andBoundingBox:(GPKGBoundingBox *)boundingBox andSrsId:(NSNumber *) srsId {
    
    GPKGGeoPackage * geoPackage;
    @try {
        geoPackage = [_manager open:database];
        [geoPackage createFeatureTableWithGeometryColumns:geometryColumns andBoundingBox:boundingBox andSrsId:srsId];
    }
    @catch (NSException *e) {
        // TODO handle this
        NSLog(@"There was a problem creating the layer, %@", e.reason);
    }
    @finally {
        [geoPackage close];
        //[_navigationController popToViewController:_geoPackageViewController animated:YES]; // TODO replace with drawer
        [self updateDatabase];
    }
    
    // TODO handle dismissing the view controllers or displaying an error message
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
    [_mapDelegate setupTileBoundingBoxGuide: self.boundingBoxGuideViewController.view];
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
    [_mapDelegate setupTileBoundingBoxGuide: self.boundingBoxGuideViewController.view];
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
