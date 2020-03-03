//
//  GPKGSEditTileOverlayViewController.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/29/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSEditTileOverlayViewController.h"
#import "GPKGSBoundingBoxViewController.h"
#import "MCUtils.h"
#import "MCProperties.h"
#import "MCConstants.h"
#import "MCDecimalValidator.h"
#import "GPKGGeoPackage.h"
#import "GPKGSFeatureTilesDrawViewController.h"
#import "SFPProjectionTransform.h"
#import "SFPProjectionConstants.h"
#import "GPKGTileBoundingBoxUtils.h"
#import "GPKGFeatureIndexManager.h"

NSString * const GPKGS_EDIT_TILE_OVERLAY_SEG_BOUNDING_BOX = @"boundingBox";
NSString * const GPKGS_EDIT_TILE_OVERLAY_SEG_FEATURE_TILES_DRAW = @"featureTilesDraw";

@interface GPKGSEditTileOverlayViewController ()

@property (nonatomic, strong) MCDecimalValidator * zoomValidator;
@property (nonatomic, strong) NSNumberFormatter * numberFormatter;

@end

@implementation GPKGSEditTileOverlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.numberFormatter = [[NSNumberFormatter alloc] init];
    self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    // Check if indexed
    GPKGGeoPackage * geoPackage = [self.manager open:self.database];
    @try {
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:self.featureTable];
        GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
        @try{
            self.data.indexed = [indexer isIndexed];
            if(self.data.indexed){
                [self.warningLabel setText:[MCProperties getValueOfProperty:GPKGS_PROP_EDIT_FEATURE_OVERLAY_INDEX_VALIDATION]];
                [self.warningLabel setTextColor:[UIColor greenColor]];
            }else{
                [self.warningLabel setText:[MCProperties getValueOfProperty:GPKGS_PROP_EDIT_FEATURE_OVERLAY_INDEX_WARNING]];
            }
        }@finally{
            [indexer close];
        }
    }
    @finally {
        [geoPackage close];
    }
    
    NSNumber * minZoomValidation = [MCProperties getNumberValueOfProperty:GPKGS_PROP_LOAD_TILES_MIN_ZOOM_DEFAULT];
    NSNumber * maxZoomValidation = [MCProperties getNumberValueOfProperty:GPKGS_PROP_LOAD_TILES_MAX_ZOOM_DEFAULT];
    self.zoomValidator = [[MCDecimalValidator alloc] initWithMinimumNumber:minZoomValidation andMaximumNumber:maxZoomValidation];
    
    [self.minZoomTextField setDelegate:self.zoomValidator];
    [self.maxZoomTextField setDelegate:self.zoomValidator];
    
    if(self.data != nil){
        
        if(self.data.minZoom == nil || [minZoomValidation intValue] > [self.data.minZoom intValue]){
            self.data.minZoom = minZoomValidation;
        }
        if(self.data.maxZoom == nil || [maxZoomValidation intValue] < [self.data.maxZoom intValue]){
            self.data.maxZoom = maxZoomValidation;
        }
        if([self.data.minZoom intValue] > [self.data.maxZoom intValue]){
            self.data.minZoom = self.data.maxZoom;
        }
        
        [self.minZoomTextField setText:[self.data.minZoom stringValue]];
        [self.maxZoomTextField setText:[self.data.maxZoom stringValue]];
        
        if(self.data.maxFeaturesPerTile != nil){
            [self.maxFeaturesPerTileTextField setText:[self.data.maxFeaturesPerTile stringValue]];
        }
    }
    
    UIToolbar *keyboardToolbar = [MCUtils buildKeyboardDoneToolbarWithTarget:self andAction:@selector(doneButtonPressed)];
    
    self.minZoomTextField.inputAccessoryView = keyboardToolbar;
    self.maxZoomTextField.inputAccessoryView = keyboardToolbar;
    self.maxFeaturesPerTileTextField.inputAccessoryView = keyboardToolbar;
}

- (void) doneButtonPressed {
    [self.minZoomTextField resignFirstResponder];
    [self.maxZoomTextField resignFirstResponder];
    [self.maxFeaturesPerTileTextField resignFirstResponder];
}

- (IBAction)minZoomChanged:(id)sender {
    self.data.minZoom = [self.numberFormatter numberFromString:self.minZoomTextField.text];
}

- (IBAction)maxZoomChanged:(id)sender {
    self.data.maxZoom = [self.numberFormatter numberFromString:self.maxZoomTextField.text];
}

- (IBAction)maxFeaturesPerTileChanged:(id)sender {
    self.data.maxFeaturesPerTile = [self.numberFormatter numberFromString:self.maxFeaturesPerTileTextField.text];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([segue.identifier isEqualToString:GPKGS_EDIT_TILE_OVERLAY_SEG_BOUNDING_BOX])
    {
        [self setBoundingBox];
        GPKGSBoundingBoxViewController *boundingBoxViewController = segue.destinationViewController;
        boundingBoxViewController.delegate = self;
        if(self.data.boundingBox != nil){
            boundingBoxViewController.boundingBox = self.data.boundingBox;
        }
    } else if([segue.identifier isEqualToString:GPKGS_EDIT_TILE_OVERLAY_SEG_FEATURE_TILES_DRAW]){
        GPKGSFeatureTilesDrawViewController *featureTilesDrawViewController = segue.destinationViewController;
        featureTilesDrawViewController.data = self.data.featureTilesDraw;
    }
}

-(void) setBoundingBox{
    
    if(self.data.boundingBox == nil){
        GPKGGeoPackage * geoPackage = [self.manager open:self.database];
        @try {
            GPKGContentsDao * contentsDao =  [geoPackage getContentsDao];
            GPKGContents * contents = (GPKGContents *)[contentsDao queryForIdObject:self.featureTable];
            if(contents != nil){
                GPKGBoundingBox * boundingBox = [contents getBoundingBox];
                GPKGBoundingBox * worldGeodeticBoundingBox = nil;
                if(boundingBox != nil){
                    SFPProjection * projection = [contentsDao getProjection:contents];
                    
                    SFPProjectionTransform * webMercatorTransform = [[SFPProjectionTransform alloc] initWithFromProjection:projection andToEpsg:PROJ_EPSG_WEB_MERCATOR];
                    if([projection isUnit:SFP_UNIT_DEGREES]){
                        boundingBox = [GPKGTileBoundingBoxUtils boundDegreesBoundingBoxWithWebMercatorLimits:boundingBox];
                    }
                    GPKGBoundingBox * webMercatorBoundingBox = [boundingBox transform:webMercatorTransform];
                    SFPProjectionTransform * worldGeodeticTransform = [[SFPProjectionTransform alloc] initWithFromEpsg:PROJ_EPSG_WEB_MERCATOR andToEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
                    worldGeodeticBoundingBox = [webMercatorBoundingBox transform:worldGeodeticTransform];
                }else{
                    worldGeodeticBoundingBox = [[GPKGBoundingBox alloc] initWithMinLongitudeDouble:-PROJ_WGS84_HALF_WORLD_LON_WIDTH andMinLatitudeDouble:PROJ_WEB_MERCATOR_MIN_LAT_RANGE andMaxLongitudeDouble:PROJ_WGS84_HALF_WORLD_LON_WIDTH andMaxLatitudeDouble:PROJ_WEB_MERCATOR_MAX_LAT_RANGE];
                }
                
                self.data.boundingBox = worldGeodeticBoundingBox;
            }
        }
        @catch (NSException *exception) {
            // don't preset the bounding box
        }
        @finally {
            [geoPackage close];
        }
    }
    
}

- (void)boundingBoxViewController:(GPKGBoundingBox *) boundingBox{
    self.data.boundingBox = boundingBox;
}

@end
