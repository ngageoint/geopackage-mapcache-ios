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

@interface GPKGSMapViewController ()

@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGSDatabases *active;
@property (nonatomic, strong) NSMutableDictionary * geoPackages;
@property (nonatomic, strong) GPKGBoundingBox * featuresBoundingBox;
@property (nonatomic, strong) GPKGBoundingBox * tilesBoundingBox;
@property (nonatomic) BOOL featureOverlayTiles;

@end

@implementation GPKGSMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.mapView.delegate = self;
    self.manager = [GPKGGeoPackageFactory getManager];
    self.active = [GPKGSDatabases getInstance];
    self.geoPackages = [[NSMutableDictionary alloc] init];
    [self updateWithZoom:self.active.modified];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if(self.active.modified){
        [self.active setModified:false];
        // TODO
        [self updateWithZoom:true];
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

-(int) updateWithZoom: (BOOL) zoom{
    
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
    int maxFeatures = [self getMaxFeatures];
    
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
                }
             
                for(GPKGSFeatureOverlayTable * featureOverlay in [database getFeatureOverlays]){
                    // TODO
                }
            } else{
                [self.active removeDatabase:database.name andPreserveOverlays:false];
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
                count = [self displayFeaturesWithDatabase:databaseName andFeatures:features andCount:count andMaxFeatures:maxFeatures];
                if(count >= maxFeatures){
                    break;
                }
            }
        }
    }
    
    if(zoom){
        [self zoomToActive];
    }
    
    return count;
}

-(void) zoomToActive{
    
    GPKGBoundingBox * bbox = self.featuresBoundingBox;
    
    float paddingPercentage;
    if(bbox == nil){
        bbox = self.tilesBoundingBox;
        if(self.featureOverlayTiles){
            paddingPercentage = 10 * .01; //TODO
        }else{
            paddingPercentage = 0 * .01; //TODO
        }
    }else{
        paddingPercentage = 10 * .01f; //TODO
    }
    
    if(bbox != nil){
        
        MKCoordinateRegion coordRegion = [bbox getCoordinateRegion];
        [self.mapView setRegion:coordRegion animated:true];
    }
}

-(void) displayTiles: (GPKGSTileTable *) tiles{
    
    GPKGGeoPackage * geoPackage = [self.geoPackages objectForKey:tiles.database];
    
    GPKGTileDao * tileDao = [geoPackage getTileDaoWithTableName:tiles.name];
    
    MKTileOverlay * overlay = [GPKGOverlayFactory getTileOverlayWithTileDao:tileDao];
    overlay.canReplaceMapContent = true;
    
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
    
    [self.mapView addOverlay:overlay];
}

-(int) displayFeaturesWithDatabase: (NSString *) database andFeatures: (NSString *) features andCount: (int) count andMaxFeatures: (int) maxFeatures{
    
    GPKGGeoPackage * geoPackage = [self.geoPackages objectForKey:database];
    GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:features];
    
    GPKGResultSet * results = [featureDao queryForAll];
    @try {
        while(count < maxFeatures && [results moveToNext]){
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
                [GPKGMapShapeConverter addMapShape:shape toMapView:self.mapView];
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
    return 1000; // TODO
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
