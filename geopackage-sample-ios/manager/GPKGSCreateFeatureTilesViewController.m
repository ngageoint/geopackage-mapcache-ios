//
//  GPKGSCreateFeatureTilesViewController.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/28/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSCreateFeatureTilesViewController.h"
#import "GPKGSGenerateTilesViewController.h"
#import "GPKGSFeatureTilesDrawViewController.h"
#import "GPKGFeatureIndexer.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGProjectionTransform.h"
#import "GPKGProjectionConstants.h"
#import "GPKGTileBoundingBoxUtils.h"
#import "GPKGSLoadTilesTask.h"
#import "GPKGSUtils.h"

NSString * const GPKGS_MANAGER_CREATE_FEATURE_TILES_SEG_GENERATE_TILES = @"generateTiles";
NSString * const GPKGS_MANAGER_CREATE_FEATURE_TILES_SEG_FEATURE_TILES_DRAW = @"featureTilesDraw";

@interface GPKGSCreateFeatureTilesViewController ()

@property (nonatomic, strong) GPKGSGenerateTilesData *generateTilesData;
@property (nonatomic, strong) GPKGSFeatureTilesDrawData *featureTilesDrawData;
@property (nonatomic) BOOL indexed;

@end

@implementation GPKGSCreateFeatureTilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.databaseValue setText:self.table.database];
    
    // Check if indexed
    GPKGGeoPackage * geoPackage = [self.manager open:self.table.database];
    @try {
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:self.table.name];
        GPKGFeatureIndexer * indexer = [[GPKGFeatureIndexer alloc] initWithFeatureDao:featureDao];
        self.indexed = [indexer isIndexed];
        if(self.indexed){
            [self.warningLabel setHidden:true];
        }else{
            [self.warningLabel setText:[GPKGSProperties getValueOfProperty:GPKGS_PROP_FEATURE_TILES_INDEX_WARNING]];
        }
    }
    @finally {
        [geoPackage close];
    }
    
    // Set a default name
    [self.nameValue setText:[NSString stringWithFormat:@"%@%@", self.table.name, [GPKGSProperties getValueOfProperty:GPKGS_PROP_FEATURE_TILES_NAME_SUFFIX]]];
    
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
    
    @try {
        
        NSString * tableName = self.nameValue.text;
        if(tableName == nil || [tableName length] == 0){
            [NSException raise:@"Table Name" format:@"Name is required"];
        }
        
        GPKGSGenerateTilesData * generateTiles = self.generateTilesData;
        int minZoom = [generateTiles.minZoom intValue];
        int maxZoom = [generateTiles.maxZoom intValue];
        
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
        
        GPKGGeoPackage * geoPackage = [self.manager open:self.table.database];
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:self.table.name];
        
        // Load tiles
        GPKGFeatureTiles * featureTiles = [[GPKGFeatureTiles alloc] initWithFeatureDao:featureDao];
        
        [featureTiles setIndexQuery:self.indexed];
        
        // Basic colors
        /*
        + (UIColor *)blackColor;      // 0.0 white
        + (UIColor *)darkGrayColor;   // 0.333 white
        + (UIColor *)lightGrayColor;  // 0.667 white
        + (UIColor *)whiteColor;      // 1.0 white
        + (UIColor *)grayColor;       // 0.5 white
        + (UIColor *)redColor;        // 1.0, 0.0, 0.0 RGB
        + (UIColor *)greenColor;      // 0.0, 1.0, 0.0 RGB
        + (UIColor *)blueColor;       // 0.0, 0.0, 1.0 RGB
        + (UIColor *)cyanColor;       // 0.0, 1.0, 1.0 RGB
        + (UIColor *)yellowColor;     // 1.0, 1.0, 0.0 RGB
        + (UIColor *)magentaColor;    // 1.0, 0.0, 1.0 RGB
        + (UIColor *)orangeColor;     // 1.0, 0.5, 0.0 RGB
        + (UIColor *)purpleColor;     // 0.5, 0.0, 0.5 RGB
        + (UIColor *)brownColor;      // 0.6, 0.4, 0.2 RGB
        + (UIColor *)clearColor;      // 0.0 white, 0.0 alpha
         */
        
        double pointRadius = 50.0;
        UIColor * pointColor = [UIColor redColor];
        int pointAlpha = 240;
        double lineStrokeWidth = 20.0;
        UIColor * lineColor = [UIColor blueColor];
        int lineAlpha = 30;
        double polygonStrokeWidth = 10.0;
        UIColor * polygonColor = [UIColor yellowColor];
        int polygonAlpha = 200.0;
        BOOL fillPolygon = true;
        UIColor * polygonFillColor = [UIColor cyanColor];
        int polygonFillAlpha = 20.0;
        
        pointColor = [UIColor colorWithCGColor:CGColorCreateCopyWithAlpha(pointColor.CGColor, pointAlpha/255.0)];
        lineColor = [UIColor colorWithCGColor:CGColorCreateCopyWithAlpha(lineColor.CGColor, lineAlpha/255.0)];
        polygonColor = [UIColor colorWithCGColor:CGColorCreateCopyWithAlpha(polygonColor.CGColor, polygonAlpha/255.0)];
        polygonFillColor = [UIColor colorWithCGColor:CGColorCreateCopyWithAlpha(polygonFillColor.CGColor, polygonFillAlpha/255.0)];
        
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
        [GPKGSLoadTilesTask loadTilesWithCallback:self andGeoPackage:geoPackage andTable:tableName andFeatureTiles:featureTiles andMinZoom:minZoom andMaxZoom:maxZoom andCompressFormat:generateTiles.compressFormat andCompressQuality:[generateTiles.compressQuality intValue] andCompressScale:[generateTiles.compressScale intValue] andStandardFormat:generateTiles.standardWebMercatorFormat andBoundingBox:boundingBox andLabel:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_CREATE_FEATURE_TILES_LABEL]];
        
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
        self.featureTilesDrawData = [[GPKGSFeatureTilesDrawData alloc] init];
        featureTilesDrawViewController.data = self.featureTilesDrawData;
    }
}

-(void)setGenerateTilesFields{
    
    self.generateTilesData = [[GPKGSGenerateTilesData alloc] init];
    
    GPKGGeoPackage * geoPackage = [self.manager open:self.table.database];
    @try {
        GPKGContentsDao * contentsDao =  [geoPackage getContentsDao];
        GPKGContents * contents = (GPKGContents *)[contentsDao queryForIdObject:self.table.name];
        if(contents != nil){
            GPKGBoundingBox * boundingBox = [contents getBoundingBox];
            GPKGProjection * projection = [contentsDao getProjection:contents];
            
            // Try to find a good zoom starting point
            GPKGProjectionTransform * webMercatorTransform = [[GPKGProjectionTransform alloc] initWithFromProjection:projection andToEpsg:PROJ_EPSG_WEB_MERCATOR];
            if([projection.epsg intValue] == PROJ_EPSG_WORLD_GEODETIC_SYSTEM){
                boundingBox = [GPKGTileBoundingBoxUtils boundWgs84BoundingBoxWithWebMercatorLimits:boundingBox];
            }
            GPKGBoundingBox * webMercatorBoundingBox = [webMercatorTransform transformWithBoundingBox:boundingBox];
            int zoomLevel = [GPKGTileBoundingBoxUtils getZoomLevelWithWebMercatorBoundingBox:webMercatorBoundingBox];
            int maxZoomLevel = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_LOAD_TILES_MAX_ZOOM_DEFAULT] intValue];
            zoomLevel = MAX(0, MIN(zoomLevel, maxZoomLevel - 1));
            self.generateTilesData.minZoom = [NSNumber numberWithInt:zoomLevel];
            self.generateTilesData.maxZoom = [NSNumber numberWithInt:maxZoomLevel];
            
            GPKGProjectionTransform * worldGeodeticTransform = [[GPKGProjectionTransform alloc] initWithFromEpsg:PROJ_EPSG_WEB_MERCATOR andToEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
            GPKGBoundingBox * worldGeodeticBoundingBox = [worldGeodeticTransform transformWithBoundingBox:webMercatorBoundingBox];
            self.generateTilesData.boundingBox = worldGeodeticBoundingBox;
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

-(void) onLoadTilesFailure: (NSString *) result{
    if(self.delegate != nil){
        [self.delegate createFeatureTilesViewController:self createdTiles:0 withError:result];
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
