//
//  GPKGSCreateFeatureTilesViewController.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/28/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSCreateFeatureTilesViewController.h"
#import "GPKGSGenerateTilesViewController.h"
#import "GPKGSFeatureTilesDrawViewController.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGProjectionTransform.h"
#import "GPKGProjectionConstants.h"
#import "GPKGTileBoundingBoxUtils.h"
#import "GPKGSLoadTilesTask.h"
#import "GPKGSUtils.h"
#import "GPKGProjectionFactory.h"
#import "GPKGNumberFeaturesTile.h"

NSString * const GPKGS_MANAGER_CREATE_FEATURE_TILES_SEG_GENERATE_TILES = @"generateTiles";
NSString * const GPKGS_MANAGER_CREATE_FEATURE_TILES_SEG_FEATURE_TILES_DRAW = @"featureTilesDraw";

@interface GPKGSCreateFeatureTilesViewController ()

@property (nonatomic) BOOL indexed;

@end

@implementation GPKGSCreateFeatureTilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.databaseValue setText:self.database];
    
    // Check if indexed
    GPKGGeoPackage * geoPackage = [self.manager open:self.database];
    @try {
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:self.name];
        GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
        self.indexed = [indexer isIndexed];
        if(self.indexed){
            [self.warningLabel setText:[GPKGSProperties getValueOfProperty:GPKGS_PROP_FEATURE_TILES_INDEX_VALIDATION]];
            [self.warningLabel setTextColor:[UIColor greenColor]];
        }else{
            [self.warningLabel setText:[GPKGSProperties getValueOfProperty:GPKGS_PROP_FEATURE_TILES_INDEX_WARNING]];
        }
    }
    @finally {
        [geoPackage close];
    }
    
    // Set a default name
    [self.nameValue setText:[NSString stringWithFormat:@"%@%@", self.name, [GPKGSProperties getValueOfProperty:GPKGS_PROP_FEATURE_TILES_NAME_SUFFIX]]];
    
    UIToolbar *keyboardToolbar = [GPKGSUtils buildKeyboardDoneToolbarWithTarget:self andAction:@selector(doneButtonPressed)];
    
    self.nameValue.inputAccessoryView = keyboardToolbar;
}

- (void) doneButtonPressed {
    [self.nameValue resignFirstResponder];
}

- (IBAction)cancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)createButton:(id)sender {
    
    [self.view setUserInteractionEnabled:NO];
    
    @try {
        
        NSString * tableName = self.nameValue.text;
        if(tableName == nil || [tableName length] == 0){
            [NSException raise:@"Table Name" format:@"Name is required"];
        }
        
        GPKGSGenerateTilesData * generateTiles = self.generateTilesData;
        int minZoom = [generateTiles.minZoom intValue];
        int maxZoom = [generateTiles.maxZoom intValue];
        
        NSNumber * maxFeatures = generateTiles.maxFeaturesPerTile;
        
        if (minZoom > maxZoom) {
            [NSException raise:@"Zoom Range" format:@"Min zoom (%d) can not be larger than max zoom (%d)", minZoom, maxZoom];
        }
        
        GPKGBoundingBox * boundingBox = generateTiles.boundingBox;
        
        if ([boundingBox.minLatitude doubleValue] > [boundingBox.maxLatitude doubleValue]) {
            [NSException raise:@"Latitude Range" format:@"Min latitude (%@) can not be larger than max latitude (%@)", boundingBox.minLatitude, boundingBox.maxLatitude];
        }
        
        if ([boundingBox.minLongitude doubleValue] > [boundingBox.maxLongitude doubleValue]) {
            [NSException raise:@"Longitude Range" format:@"Min longitude (%@) can not be larger than max longitude (%@)", boundingBox.minLongitude, boundingBox.maxLongitude];
        }
        
        GPKGGeoPackage * geoPackage = [self.manager open:self.database];
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:self.name];
        
        // Load tiles
        GPKGFeatureTiles * featureTiles = [[GPKGFeatureTiles alloc] initWithFeatureDao:featureDao];
        [featureTiles setMaxFeaturesPerTile:maxFeatures];
        if(maxFeatures != nil){
            [featureTiles setMaxFeaturesTileDraw:[[GPKGNumberFeaturesTile alloc] init]];
        }
        
        GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
        if([indexer isIndexed]){
            [featureTiles setIndexManager:indexer];
        }
        
        double pointRadius = [self.featureTilesDrawData.pointRadius doubleValue];
        UIColor * pointColor = [self.featureTilesDrawData getPointAlphaColor];
        double lineStrokeWidth = [self.featureTilesDrawData.lineStroke doubleValue];
        UIColor * lineColor = [self.featureTilesDrawData getLineAlphaColor];
        double polygonStrokeWidth = [self.featureTilesDrawData.polygonStroke doubleValue];
        UIColor * polygonColor = [self.featureTilesDrawData getPolygonAlphaColor];
        BOOL fillPolygon = self.featureTilesDrawData.polygonFill;
        UIColor * polygonFillColor = [self.featureTilesDrawData getPolygonFillAlphaColor];
        
        [featureTiles setPointRadius:pointRadius];
        [featureTiles setPointColor:pointColor];
        [featureTiles setLineStrokeWidth:lineStrokeWidth];
        [featureTiles setLineColor:lineColor];
        [featureTiles setPolygonStrokeWidth:polygonStrokeWidth];
        [featureTiles setPolygonColor:polygonColor];
        [featureTiles setFillPolygon:fillPolygon];
        [featureTiles setPolygonFillColor:polygonFillColor];
        
        // Using a point icon
        /*
         UIImage * image = [UIImage imageNamed:@"Point"];
         GPKGFeatureTilePointIcon * pointIcon = [[GPKGFeatureTilePointIcon alloc] initWithIcon:image];
         [pointIcon pinIcon];
         [featureTiles setPointIcon:pointIcon];
         */
        
        [featureTiles calculateDrawOverlap];
        [GPKGSLoadTilesTask loadTilesWithCallback:self andGeoPackage:geoPackage andTable:tableName andFeatureTiles:featureTiles andMinZoom:minZoom andMaxZoom:maxZoom andCompressFormat:generateTiles.compressFormat andCompressQuality:[generateTiles.compressQuality intValue] andCompressScale:[generateTiles.compressScale intValue] andStandardFormat:generateTiles.standardWebMercatorFormat andBoundingBox:boundingBox andAuthority:PROJ_AUTHORITY_EPSG andCode:[NSString stringWithFormat:@"%d",PROJ_EPSG_WEB_MERCATOR] andLabel:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_CREATE_FEATURE_TILES_LABEL]];
        
    }
    @catch (NSException *e) {
        if(self.delegate != nil){
            [self.delegate createFeatureTilesViewController:self createdTiles:0 withError:[e description]];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([segue.identifier isEqualToString:GPKGS_MANAGER_CREATE_FEATURE_TILES_SEG_GENERATE_TILES])
    {
        [self setGenerateTilesFields];
        GPKGSGenerateTilesViewController *generateTilesViewController = segue.destinationViewController;
        generateTilesViewController.data = self.generateTilesData;
    } else if([segue.identifier isEqualToString:GPKGS_MANAGER_CREATE_FEATURE_TILES_SEG_FEATURE_TILES_DRAW]){
        GPKGSFeatureTilesDrawViewController *featureTilesDrawViewController = segue.destinationViewController;
        featureTilesDrawViewController.data = self.featureTilesDrawData;
    }
}

-(void)setGenerateTilesFields{
    
    GPKGGeoPackage * geoPackage = [self.manager open:self.database];
    @try {
        GPKGContentsDao * contentsDao =  [geoPackage getContentsDao];
        GPKGContents * contents = (GPKGContents *)[contentsDao queryForIdObject:self.name];
        if(contents != nil){
            
            GPKGBoundingBox * webMercatorBoundingBox = nil;
            GPKGBoundingBox * boundingBox = nil;
            GPKGProjection * projection = nil;
            if(self.generateTilesData.boundingBox != nil){
                boundingBox = self.generateTilesData.boundingBox;
                projection = [GPKGProjectionFactory projectionWithEpsgInt: PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
            }else{
                boundingBox = [contents getBoundingBox];
                if(boundingBox == nil){
                    boundingBox = [[GPKGBoundingBox alloc] initWithMinLongitudeDouble:-PROJ_WGS84_HALF_WORLD_LON_WIDTH andMaxLongitudeDouble:PROJ_WGS84_HALF_WORLD_LON_WIDTH andMinLatitudeDouble:PROJ_WEB_MERCATOR_MIN_LAT_RANGE andMaxLatitudeDouble:PROJ_WEB_MERCATOR_MAX_LAT_RANGE];
                    projection = [GPKGProjectionFactory projectionWithEpsgInt: PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
                }else{
                    projection = [contentsDao getProjection:contents];
                }
            }
            
            GPKGProjectionTransform * webMercatorTransform = [[GPKGProjectionTransform alloc] initWithFromProjection:projection andToEpsg:PROJ_EPSG_WEB_MERCATOR];
            if([projection getUnit] == GPKG_UNIT_DEGREES){
                boundingBox = [GPKGTileBoundingBoxUtils boundDegreesBoundingBoxWithWebMercatorLimits:boundingBox];
            }
            webMercatorBoundingBox = [webMercatorTransform transformWithBoundingBox:boundingBox];
            
            // Try to find a good zoom starting point
            int zoomLevel = [GPKGTileBoundingBoxUtils getZoomLevelWithWebMercatorBoundingBox:webMercatorBoundingBox];
            int maxZoomLevel = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_LOAD_TILES_MAX_ZOOM_DEFAULT] intValue];
            zoomLevel = MAX(0, MIN(zoomLevel, maxZoomLevel - 1));
            self.generateTilesData.minZoom = [NSNumber numberWithInt:zoomLevel];
            self.generateTilesData.maxZoom = [NSNumber numberWithInt:maxZoomLevel];
            
            // Check if indexed and set max features
            GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:self.name];
            GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
            BOOL indexed = [indexer isIndexed];
            self.generateTilesData.supportsMaxFeatures = true;
            if(indexed){
                NSNumber * maxFeaturesPerTile = [GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_FEATURE_TILES_LOAD_MAX_FEATURES_PER_TILE_DEFAULT];
                if([maxFeaturesPerTile intValue] >= 0){
                    self.generateTilesData.maxFeaturesPerTile = maxFeaturesPerTile;
                }
            }
            
            if(self.generateTilesData.boundingBox == nil){
                GPKGProjectionTransform * worldGeodeticTransform = [[GPKGProjectionTransform alloc] initWithFromEpsg:PROJ_EPSG_WEB_MERCATOR andToEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
                GPKGBoundingBox * worldGeodeticBoundingBox = [worldGeodeticTransform transformWithBoundingBox:webMercatorBoundingBox];
                self.generateTilesData.boundingBox = worldGeodeticBoundingBox;
            }
        }
    }
    @catch (NSException *exception) {
        // don't preset the bounding box
    }
    @finally {
        [geoPackage close];
    }
    
}

-(void) onLoadTilesCanceled: (NSString *) result withCount:(int)count{
    if(self.delegate != nil){
        [self.delegate createFeatureTilesViewController:self createdTiles:count withError:nil];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) onLoadTilesFailure: (NSString *) result withCount:(int)count{
    if(self.delegate != nil){
        [self.delegate createFeatureTilesViewController:self createdTiles:count withError:result];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) onLoadTilesCompleted:(int)count{
    if(self.delegate != nil){
        [self.delegate createFeatureTilesViewController:self createdTiles:count withError:nil];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
