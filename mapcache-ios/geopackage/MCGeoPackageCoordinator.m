//
//  GPKGSCoordinator.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/31/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "MCGeoPackageCoordinator.h"


@interface MCGeoPackageCoordinator()
@property (strong, nonatomic) MCGeopackageSingleViewController *geoPackageViewController;
@property (strong, nonatomic) id<MCGeoPackageCoordinatorDelegate> geoPackageCoordinatorDelegate;
@property (strong, nonatomic) id<NGADrawerViewDelegate> drawerDelegate;
@property (strong, nonatomic) GPKGGeoPackageManager *manager;
// @property (strong, nonatomic) UINavigationController *navigationController; // TODO replace all of the navigation controller references with drawer
@property (strong, nonatomic) id<NGADrawerViewDelegate> drawerViewDelegate;
@property (strong, nonatomic) MCFeatureLayerDetailsViewController *featureDetailsController;
@property (strong, nonatomic) MCTileLayerDetailsViewController *tileDetailsController;
@property (strong, nonatomic) MCBoundingBoxViewController *boundingBoxViewController;
@property (strong, nonatomic) MCZoomAndQualityViewController *zoomAndQualityViewController;
@property (strong, nonatomic) MCManualBoundingBoxViewController *manualBoundingBoxViewController;
@property (strong, nonatomic) UIBarButtonItem *backButton;
@property (strong, nonatomic) GPKGSDatabase *database;
@property (nonatomic, strong) GPKGSCreateTilesData * tileData;
@property (strong, nonatomic) NSMutableArray *childCoordinators;
@end


@implementation MCGeoPackageCoordinator

- (instancetype) initWithDelegate:(id<MCGeoPackageCoordinatorDelegate>)geoPackageCoordinatorDelegate andDrawerDelegate:(id<NGADrawerViewDelegate>) drawerDelegate andDatabase:(GPKGSDatabase *) database {
    self = [super init];
    
    _childCoordinators = [[NSMutableArray alloc] init];
    _manager = [GPKGGeoPackageFactory getManager];
    _geoPackageCoordinatorDelegate = geoPackageCoordinatorDelegate;
    _drawerDelegate = drawerDelegate;
    _database = database;

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
    
    MCCreateLayerViewController *createLayerViewControler = [[MCCreateLayerViewController alloc] initWithNibName:@"MCCreateLayerView" bundle:nil];
    createLayerViewControler.delegate = self;
    //[_navigationController pushViewController:createLayerViewControler animated:YES]; // TODO replace with drawer
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
    NSLog(@"Back pressed");
    [_geoPackageCoordinatorDelegate geoPackageCoordinatorCompletionHandlerForDatabase:_database.name withDelete:NO];
    // TODO Make sure the drawer is being handled properly
}


- (void) deleteLayer:(NSString *) layerName {
    GPKGGeoPackage *geoPackage = [_manager open:_database.name];
    
    @try {
        [geoPackage deleteUserTable:layerName];
        [_geoPackageViewController removeLayerNamed:layerName];
    }
    @catch (NSException *exception) {
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:[NSString stringWithFormat:@"%@ %@ - %@ Table", [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_DELETE_LABEL], _database.name, layerName]
                                 andMessage:[NSString stringWithFormat:@"%@", [exception description]]];
    }
    @finally {
        [geoPackage close];
    }
}


- (void) showLayerDetails:(GPKGUserDao *) layerDao {
    NSLog(@"In showLayerDetails with %@", layerDao.tableName);
    // TODO: Create a layer details view and show it
    
    //MCLayerCoordinator *layerCoordinator = [[MCLayerCoordinator alloc] initWithNavigationController:_navigationController andDatabase:_database andDao:layerDao]; // TODO replace with drawer
    //[_childCoordinators addObject:layerCoordinator];
    //[layerCoordinator start];
}


#pragma mark - CreateLayerViewController delegate methods
- (void) newFeatureLayer {
    NSLog(@"Adding new feature layer");
    _featureDetailsController = [[MCFeatureLayerDetailsViewController alloc] init];
    _featureDetailsController.database = _database;
    _featureDetailsController.delegate = self;
    //[_navigationController pushViewController:_featureDetailsController animated:YES]; // TODO replace with drawer
}


- (void) newTileLayer {
    NSLog(@"Adding new tile layer");
    _tileData = [[GPKGSCreateTilesData alloc] init];
    _tileDetailsController = [[MCTileLayerDetailsViewController alloc] init];
    _tileDetailsController.delegate = self;
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
        [_geoPackageViewController update];
    }
    
    // TODO handle dismissing the view controllers or displaying an error message
}


#pragma mark - MCTileLayerDetailsDelegate
- (void) tileLayerDetailsCompletionHandlerWithName:(NSString *)name URL:(NSString *) url andReferenceSystemCode:(int)referenceCode {
    _tileData.name = name;
    _tileData.loadTiles.url = url;
    _tileData.loadTiles.epsg = referenceCode;
    
    _boundingBoxViewController = [[MCBoundingBoxViewController alloc] init];
    _boundingBoxViewController.delegate = self;
    //[_navigationController pushViewController:_boundingBoxViewController animated:YES];
}


#pragma mark- MCBoundingBoxDelegate
- (void) boundingBoxCompletionHandler:(GPKGBoundingBox *)boundingBox  {
    _tileData.loadTiles.generateTiles.boundingBox = boundingBox;
    
    _zoomAndQualityViewController = [[MCZoomAndQualityViewController alloc] init];
    _zoomAndQualityViewController.delegate = self;
    //[_navigationController pushViewController:_zoomAndQualityViewController animated:YES]; // TODO replace with drawer
}


- (void) showManualBoundingBoxViewWithMinLat:(double)minLat andMaxLat:(double)maxLat andMinLon:(double)minLon andMaxLon:(double) maxLon {
    _manualBoundingBoxViewController = [[MCManualBoundingBoxViewController alloc] initWithLowerLeftLat:minLat andLowerLeftLon:minLon andUpperRightLat:maxLat andUpperRightLon:maxLon];
    _manualBoundingBoxViewController.delegate = self;
    //[_navigationController pushViewController:_manualBoundingBoxViewController animated:YES]; // TODO replace with drawer
    
}


#pragma mark- MCManualBoundingBoxDelegate
- (void) manualBoundingBoxCompletionHandlerWithLowerLeftLat:(double)lowerLeftLat andLowerLeftLon:(double)lowerLeftLon andUpperRightLat:(double)upperRightLat andUpperRightLon:(double)upperRightLon{
    [_boundingBoxViewController setBoundingBoxWithLowerLeftLat:lowerLeftLat andLowerLeftLon:lowerLeftLon andUpperRightLat:upperRightLat andUpperRightLon:upperRightLon];
    //[_navigationController popToViewController:_boundingBoxViewController animated:YES]; // TODO replace with drawer
    
}


#pragma mark- MCZoomAndQualityDelegate methods
- (void) zoomAndQualityCompletionHandlerWith:(NSNumber *) minZoom andMaxZoom:(NSNumber *) maxZoom {
    NSLog(@"In wizard, going to call completion handler");
    
    _tileData.loadTiles.generateTiles.minZoom = minZoom;
    _tileData.loadTiles.generateTiles.maxZoom = maxZoom;
    [self createTileLayer:_tileData];
}


#pragma mark - MCNewLayerWizardDelegate methods
- (void) createTileLayer:(GPKGSCreateTilesData *) tileData {
    NSLog(@"Coordinator attempting to create tiles");
    GPKGTileScaling *scaling = [GPKGSLoadTilesTask tileScaling];
    
    [GPKGSLoadTilesTask loadTilesWithCallback:self
                                  andDatabase:_database.name
                                     andTable:tileData.name
                                       andUrl:tileData.loadTiles.url
                                   andMinZoom:[tileData.loadTiles.generateTiles.minZoom intValue]
                                   andMaxZoom:[tileData.loadTiles.generateTiles.maxZoom intValue]
                            andCompressFormat:GPKG_CF_NONE // TODO: let user set this
                           andCompressQuality:[[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_LOAD_TILES_COMPRESS_QUALITY_DEFAULT] intValue]
                             andCompressScale:100 // TODO: let user set this
                            andStandardFormat:tileData.loadTiles.generateTiles.standardWebMercatorFormat
                               andBoundingBox:tileData.loadTiles.generateTiles.boundingBox
                               andTileScaling:scaling
                                 andAuthority:PROJ_AUTHORITY_EPSG
                                      andCode:[NSString stringWithFormat:@"%d",tileData.loadTiles.epsg]
                                     andLabel:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_CREATE_TILES_LABEL]];

}


#pragma mark - GPKGSLoadTilesProtocol methods
-(void) onLoadTilesCanceled: (NSString *) result withCount: (int) count {
    //TODO: fill in
    NSLog(@"Loading tiles canceled");
}


-(void) onLoadTilesFailure: (NSString *) result withCount: (int) count {
    //TODO: fill in
    NSLog(@"Loading tiles failed");
}


-(void) onLoadTilesCompleted: (int) count {
    //TODO: fill in
    NSLog(@"Loading tiles completed");
    //[_navigationController popToViewController:_geoPackageViewController animated:YES]; // TODO replace with drawer
    [_geoPackageViewController update];
}


@end
