//
//  GPKGSMapViewController.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/13/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSMapViewController.h"
#import "GPKGGeoPackageManager.h"
#import "GPKGSDatabases.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGSTileTable.h"
#import "GPKGOverlayFactory.h"
#import "GPKGProjectionTransform.h"
#import "GPKGProjectionConstants.h"
#import "GPKGTileBoundingBoxUtils.h"
#import "GPKGSFeatureOverlayTable.h"
#import "GPKGMapShapeConverter.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"

@interface GPKGSMapViewController ()

@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGSDatabases *active;
@property (nonatomic, strong) NSMutableDictionary * geoPackages;
@property (nonatomic, strong) GPKGBoundingBox * featuresBoundingBox;
@property (nonatomic, strong) GPKGBoundingBox * tilesBoundingBox;
@property (nonatomic) BOOL featureOverlayTiles;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (nonatomic, strong) NSUserDefaults * settings;
@property (atomic) int updateCountId;

@end

@implementation GPKGSMapViewController

#define TAG_MAP_TYPE 1
#define TAG_MAX_FEATURES 2

- (void)viewDidLoad {
    [super viewDidLoad];
    self.updateCountId = 0;
    self.settings = [NSUserDefaults standardUserDefaults];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    self.manager = [GPKGGeoPackageFactory getManager];
    self.active = [GPKGSDatabases getInstance];
    self.geoPackages = [[NSMutableDictionary alloc] init];
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager setDelegate:self];
    [self.locationManager requestWhenInUseAuthorization];
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if(self.active.modified){
        [self.active setModified:false];
        // TODO
        [self updateInBackgroundWithZoom:true];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch(alertView.tag){
        case TAG_MAP_TYPE:
            [self handleMapTypeWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
        case TAG_MAX_FEATURES:
            [self handleMaxFeaturesWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
    }
}

- (IBAction)zoomToActiveButton:(id)sender {
    [self zoomToActive];
}

- (IBAction)featuresButton:(id)sender {
    //TODO
}

- (IBAction)boundingBoxButton:(id)sender {
    //TODO
}

- (IBAction)userLocation:(id)sender {
    if([CLLocationManager locationServicesEnabled]){
        [self.locationManager startUpdatingLocation];
    }
}

- (IBAction)maxFeaturesButton:(id)sender {
    UIAlertView * alert = [[UIAlertView alloc]
                           initWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_MAX_FEATURES]
                           message:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_MAX_FEATURES_MESSAGE]
                           delegate:self
                           cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                           otherButtonTitles:[GPKGSProperties getValueOfProperty:GPKGS_PROP_OK_LABEL],
                           nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField* textField = [alert textFieldAtIndex:0];
    textField.keyboardType = UIKeyboardTypeNumberPad;
    [textField setText:[NSString stringWithFormat:@"%d", [self getMaxFeatures]]];
    alert.tag = TAG_MAX_FEATURES;
    [alert show];
}

- (void) handleMaxFeaturesWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex > 0){
        NSString * maxFeatures = [[alertView textFieldAtIndex:0] text];
        if(maxFeatures != nil && [maxFeatures length] > 0){
            @try {
                NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                formatter.numberStyle = NSNumberFormatterDecimalStyle;
                NSNumber *maxFeaturesNumber = [formatter numberFromString:maxFeatures];
                [self.settings setInteger:[maxFeaturesNumber integerValue] forKey:GPKGS_PROP_MAP_MAX_FEATURES];
                [self.settings synchronize];
                [self updateInBackgroundWithZoom:false];
            }
            @catch (NSException *e) {
                NSLog(@"Invalid max features value: %@, Error: %@", maxFeatures, [e description]);
            }
        }
    }
}

- (IBAction)mapType:(id)sender {
    UIAlertView * alert = [[UIAlertView alloc]
                           initWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE]
                           message:nil
                           delegate:self
                           cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                           otherButtonTitles:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_STANDARD],
                           [GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_SATELLITE],
                           [GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_HYBRID],
                           nil];
    alert.tag = TAG_MAP_TYPE;
    [alert show];
}

- (void) handleMapTypeWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex > 0){
        MKMapType mapType;
        switch(buttonIndex){
            case 1:
                mapType = MKMapTypeStandard;
                break;
            case 2:
                mapType = MKMapTypeSatellite;
                break;
            case 3:
                mapType = MKMapTypeHybrid;
                break;
            default:
                mapType = MKMapTypeStandard;
        }
        [self.mapView setMapType:mapType];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    CLLocation * userLocation = self.mapView.userLocation.location;
    if(userLocation != nil){
        [self.mapView setCenterCoordinate:userLocation.coordinate animated:YES];
        [self.locationManager stopUpdatingLocation];
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id)overlay {
    MKOverlayRenderer * rendered = nil;
    if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        rendered = [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    }else if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer * polylineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        polylineRenderer.strokeColor = [UIColor blackColor];
        polylineRenderer.lineWidth = 1.0;
        rendered = polylineRenderer;
    }
    else if ([overlay isKindOfClass:[MKPolygon class]]) {
        MKPolygonRenderer * polygonRenderer = [[MKPolygonRenderer alloc] initWithPolygon:overlay];
        polygonRenderer.strokeColor = [UIColor blackColor];
        polygonRenderer.lineWidth = 1.0;
        rendered = polygonRenderer;
    }
    return rendered;
}

-(int) updateInBackgroundWithZoom: (BOOL) zoom{
    
    int updateId = ++self.updateCountId;
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    for(GPKGGeoPackage * geoPackage in [self.geoPackages allValues]){
        @try {
            [geoPackage close];
        }
        @catch (NSException *exception) {
        }
    }
    [self.geoPackages removeAllObjects];
    self.featuresBoundingBox = nil;
    self.tilesBoundingBox = nil;
    self.featureOverlayTiles = false;
    int maxFeatures = [self getMaxFeatures];

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        [self updateWithId: updateId andZoom:zoom andMaxFeatures:maxFeatures];
    });
}

-(BOOL) updateCanceled: (int) updateId{
    BOOL canceled = updateId < self.updateCountId;
    return canceled;
}

-(int) updateWithId: (int) updateId andZoom: (BOOL) zoom andMaxFeatures: (int) maxFeatures{
    
    int count = 0;
    
    if(self.active != nil){
        
        NSArray * activeDatabases = [[NSArray alloc] initWithArray:[self.active getDatabases]];
        for(GPKGSDatabase * database in activeDatabases){
            
            GPKGGeoPackage * geoPackage = [self.manager open:database.name];
            
            if(geoPackage != nil){
                [self.geoPackages setObject:geoPackage forKey:database.name];
                
                for(GPKGSTileTable * tiles in [database getTiles]){
                    @try {
                        [self displayTiles:tiles];
                    }
                    @catch (NSException *e) {
                        NSLog(@"%@", [e description]);
                    }
                    if([self updateCanceled:updateId]){
                        break;
                    }
                }
             
                for(GPKGSFeatureOverlayTable * featureOverlay in [database getFeatureOverlays]){
                    // TODO
                    if([self updateCanceled:updateId]){
                        break;
                    }
                }
            } else{
                [self.active removeDatabase:database.name andPreserveOverlays:false];
            }
            
            if([self updateCanceled:updateId]){
                break;
            }
        }
        
        NSMutableDictionary * featureTables = [[NSMutableDictionary alloc] init];
        // TODO edit feature mode
        
        for(GPKGSDatabase * database in [self.active getDatabases]){
            NSArray * features = [database getFeatures];
            if([features count] > 0){
                NSMutableArray * databaseFeatures = [[NSMutableArray alloc] init];
                [featureTables setObject:databaseFeatures forKey:database.name];
                for(GPKGSTable * features in [database getFeatures]){
                    [databaseFeatures addObject:features.name];
                }
            }
        }
        
        for(NSString * databaseName in [featureTables allKeys]){
            
            if(count >= maxFeatures){
                break;
            }
            
            NSMutableArray * databaseFeatures = [featureTables objectForKey:databaseName];
            
            for(NSString * features in databaseFeatures){
                count = [self displayFeaturesWithId:updateId andDatabase:databaseName andFeatures:features andCount:count andMaxFeatures:maxFeatures];
                if([self updateCanceled:updateId] || count >= maxFeatures){
                    break;
                }
            }
            
            if([self updateCanceled:updateId]){
                break;
            }
        }
    }
    
    if(zoom){
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self zoomToActive];
        });
    }
    
    return count;
}

-(void) zoomToActive{
    
    GPKGBoundingBox * bbox = self.featuresBoundingBox;
    
    float paddingPercentage;
    if(bbox == nil){
        bbox = self.tilesBoundingBox;
        if(self.featureOverlayTiles){
            paddingPercentage = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_FEATURE_TILES_ZOOM_PADDING_PERCENTAGE] intValue] * .01;
        }else{
            paddingPercentage = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_TILES_ZOOM_PADDING_PERCENTAGE] intValue] * .01;
        }
    }else{
        paddingPercentage = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_FEATURES_ZOOM_PADDING_PERCENTAGE] intValue] * .01f;
    }
    
    if(bbox != nil){

        struct GPKGBoundingBoxSize size = [bbox sizeInMeters];
        double expandedHeight = size.height + (2 * (size.height * paddingPercentage));
        double expandedWidth = size.width + (2 * (size.width * paddingPercentage));
        
        CLLocationCoordinate2D center = [bbox getCenter];
        MKCoordinateRegion expandedRegion = MKCoordinateRegionMakeWithDistance(center, expandedHeight, expandedWidth);
        
        [self.mapView setRegion:expandedRegion animated:true];
    }
}

-(void) displayTiles: (GPKGSTileTable *) tiles{
    
    GPKGGeoPackage * geoPackage = [self.geoPackages objectForKey:tiles.database];
    
    GPKGTileDao * tileDao = [geoPackage getTileDaoWithTableName:tiles.name];
    
    MKTileOverlay * overlay = [GPKGOverlayFactory getTileOverlayWithTileDao:tileDao];
    overlay.canReplaceMapContent = false;
    
    GPKGTileMatrixSet * tileMatrixSet = tileDao.tileMatrixSet;
    GPKGContents * contents = [[geoPackage getTileMatrixSetDao] getContents:tileMatrixSet];
    
    [self displayTilesWithOverlay:overlay andGeoPackage:geoPackage andContents:contents andSpecifiedBoundingBox:nil];
}

-(void) displayTilesWithOverlay: (MKTileOverlay *) overlay andGeoPackage: (GPKGGeoPackage *) geoPackage andContents: (GPKGContents *) contents andSpecifiedBoundingBox: (GPKGBoundingBox *) specifiedBoundingBox{
    
    GPKGContentsDao * contentsDao = [geoPackage getContentsDao];
    GPKGProjection * projection = [contentsDao getProjection:contents];
    
    GPKGProjectionTransform * transformToWebMercator = [[GPKGProjectionTransform alloc] initWithFromProjection:projection andToEpsg:PROJ_EPSG_WEB_MERCATOR];
    GPKGBoundingBox * webMercatorBoundingBox = [transformToWebMercator transformWithBoundingBox:[contents getBoundingBox]];
    GPKGProjectionTransform * transform = [[GPKGProjectionTransform alloc] initWithFromEpsg:PROJ_EPSG_WEB_MERCATOR andToEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
    GPKGBoundingBox * boundingBox = [transform transformWithBoundingBox:webMercatorBoundingBox];
    
    if(specifiedBoundingBox != nil){
        boundingBox = [GPKGTileBoundingBoxUtils overlapWithBoundingBox:boundingBox andBoundingBox:specifiedBoundingBox];
    }
    
    if(self.tilesBoundingBox == nil){
        self.tilesBoundingBox = boundingBox;
    }else{
        [self.tilesBoundingBox setMinLongitude:MIN(self.tilesBoundingBox.minLongitude, boundingBox.minLongitude)];
        [self.tilesBoundingBox setMaxLongitude:MAX(self.tilesBoundingBox.maxLongitude, boundingBox.maxLongitude)];
        [self.tilesBoundingBox setMinLatitude:MIN(self.tilesBoundingBox.minLatitude, boundingBox.minLatitude)];
        [self.tilesBoundingBox setMaxLatitude:MAX(self.tilesBoundingBox.maxLatitude, boundingBox.maxLatitude)];
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.mapView addOverlay:overlay];
    });
}

-(int) displayFeaturesWithId: (int) updateId andDatabase: (NSString *) database andFeatures: (NSString *) features andCount: (int) count andMaxFeatures: (int) maxFeatures{
    
    GPKGGeoPackage * geoPackage = [self.geoPackages objectForKey:database];
    GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:features];
    
    GPKGResultSet * results = [featureDao queryForAll];
    @try {
        while(![self updateCanceled:updateId] && count < maxFeatures && [results moveToNext]){
            GPKGFeatureRow * row = [featureDao getFeatureRow:results];
            count = [self processFeatureRowWithDatabase:database andFeatureDao:featureDao andFeatureRow:row andCount:count andMaxFeatures:maxFeatures];
        }
    }
    @finally {
        [results close];
    }
    
    return count;
}

-(int) processFeatureRowWithDatabase: (NSString *) database andFeatureDao: (GPKGFeatureDao *) featureDao andFeatureRow: (GPKGFeatureRow *) row andCount: (int) count andMaxFeatures: (int) maxFeatures{
    GPKGProjection * projection = featureDao.projection;
    GPKGMapShapeConverter * converter = [[GPKGMapShapeConverter alloc] initWithProjection:projection];
    
    GPKGGeometryData * geometryData = [row getGeometry];
    if(geometryData != nil && !geometryData.empty){
        
        WKBGeometry * geometry = geometryData.geometry;
        
        if(geometry != nil){
            if(count++ < maxFeatures){
                GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                [self updateFeatureBoundingBox:shape];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    [GPKGMapShapeConverter addMapShape:shape toMapView:self.mapView];
                });
            }
        }
        
    }
    return count;
}

-(void) updateFeatureBoundingBox: (GPKGMapShape *) shape
{
    if(self.featuresBoundingBox != nil){
        [shape expandBoundingBox:self.featuresBoundingBox];
    }else{
        self.featuresBoundingBox = [shape boundingBox];
    }
}

-(int) getMaxFeatures{
    int maxFeatures = (int)[self.settings integerForKey:GPKGS_PROP_MAP_MAX_FEATURES];
    if(maxFeatures == 0){
        maxFeatures = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_MAX_FEATURES_DEFAULT] intValue];
    }
    return maxFeatures;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
