//
//  GPKGSCoordinator.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/31/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "GPKGSCoordinator.h"


@interface GPKGSCoordinator()
@property (strong, nonatomic) GPKGSGeopackageSingleViewController *geoPackageViewController;
@property (strong, nonatomic) id<GPKGSCoordinatorDelegate> delegate;
@property (strong, nonatomic) GPKGGeoPackageManager *manager;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) GPKGSFeatureLayerDetailsViewController *featureDetailsController;
@property (strong, nonatomic) GPKGSTileLayerDetailsViewController *tileDetailsController;
@property (strong, nonatomic) MCBoundingBoxViewController *boundingBoxViewController;
@property (strong, nonatomic) MCZoomAndQualityViewController *zoomAndQualityViewController;
@property (strong, nonatomic) UIBarButtonItem *backButton;
@property (strong, nonatomic) GPKGSDatabase *database;
@property (nonatomic, strong) GPKGSCreateTilesData * tileData;
@end


@implementation GPKGSCoordinator

- (instancetype) initWithNavigationController:(UINavigationController *) navigationController andDelegate:(id<GPKGSCoordinatorDelegate>)delegate andDatabase:(GPKGSDatabase *) database {
    self = [super init];
    
    _manager = [GPKGGeoPackageFactory getManager];
    _navigationController = navigationController;
    _delegate = delegate;
    _database = database;

    return self;
}


- (void) start {
    _geoPackageViewController = [[GPKGSGeopackageSingleViewController alloc] initWithNibName:@"SingleGeoPackageView" bundle:nil];
    _geoPackageViewController.database = _database;
    
    _geoPackageViewController.delegate = self;
    
    [_navigationController pushViewController:_geoPackageViewController animated:YES];
    [_navigationController setNavigationBarHidden:NO animated:NO];
}


#pragma mark - Delegate methods

- (void) newLayer {
    NSLog(@"Coordinator handling new layer");
    
    GPKGSCreateLayerViewController *createLayerViewControler = [[GPKGSCreateLayerViewController alloc] initWithNibName:@"CreateLayerView" bundle:nil];
    createLayerViewControler.delegate = self;
    [_navigationController pushViewController:createLayerViewControler animated:YES];
}


- (void) copyGeoPackage {
    [_navigationController popViewControllerAnimated:YES];
    [_delegate geoPackageCoordinatorCompletionHandlerForDatabase:_database.name withDelete:NO];
}


- (void) deleteGeoPackage {
    NSLog(@"Coordinator handling delete");
    [_navigationController popViewControllerAnimated:YES];
    [_delegate geoPackageCoordinatorCompletionHandlerForDatabase:_database.name withDelete:YES];
}


- (void) callCompletionHandler {
    NSLog(@"Back pressed");
    [_delegate geoPackageCoordinatorCompletionHandlerForDatabase:_database.name withDelete:NO];
}


#pragma mark - CreateLayerViewController delegate methods
- (void) newFeatureLayer {
    NSLog(@"Adding new feature layer");
    _featureDetailsController = [[GPKGSFeatureLayerDetailsViewController alloc] init];
    _featureDetailsController.database = _database;
    _featureDetailsController.delegate = self;
    [_navigationController pushViewController:_featureDetailsController animated:YES];
}


- (void) newTileLayer {
    NSLog(@"Adding new tile layer");
    _tileData = [[GPKGSCreateTilesData alloc] init];
    _tileDetailsController = [[GPKGSTileLayerDetailsViewController alloc] init];
    _tileDetailsController.delegate = self;
    [_navigationController pushViewController:_tileDetailsController animated:YES];
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
        [_navigationController popToViewController:_geoPackageViewController animated:YES];
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
    [_navigationController pushViewController:_boundingBoxViewController animated:YES];
}


#pragma mark- MCBoundingBoxDelegate
- (void) boundingBoxCompletionHandler:(GPKGBoundingBox *)boundingBox  {
    _tileData.loadTiles.generateTiles.boundingBox = boundingBox;
    
    _zoomAndQualityViewController = [[MCZoomAndQualityViewController alloc] init];
    _zoomAndQualityViewController.delegate = self;
    [_navigationController pushViewController:_zoomAndQualityViewController animated:YES];
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
    [_navigationController popToViewController:_geoPackageViewController animated:YES];
    [_geoPackageViewController update];
}


@end
