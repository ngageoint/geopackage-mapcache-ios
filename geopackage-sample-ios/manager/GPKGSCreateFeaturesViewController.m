//
//  GPKGSCreateFeaturesViewController.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/20/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSCreateFeaturesViewController.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGSDecimalValidator.h"
#import "GPKGGeoPackage.h"
#import "GPKGProjectionConstants.h"

@interface GPKGSCreateFeaturesViewController ()

@property (nonatomic, strong) GPKGSDecimalValidator * latitudeValidator;
@property (nonatomic, strong) GPKGSDecimalValidator * longitudeValidator;
@property (nonatomic, strong) NSArray * boundingBoxes;
@property (nonatomic, strong) NSArray * geometryTypes;

@end

@implementation GPKGSCreateFeaturesViewController

#define TAG_GEOMETRY_TYPES 1
#define TAG_BOUNDING_BOXES 2

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.databaseValue setText:self.database.name];
    [self.minLatValue setText:[GPKGSProperties getValueOfProperty:GPKGS_PROP_BOUNDING_BOX_DEFAULT_MIN_LATITUDE]];
    [self.maxLatValue setText:[GPKGSProperties getValueOfProperty:GPKGS_PROP_BOUNDING_BOX_DEFAULT_MAX_LATITUDE]];
    [self.minLonValue setText:[GPKGSProperties getValueOfProperty:GPKGS_PROP_BOUNDING_BOX_DEFAULT_MIN_LONGITUDE]];
    [self.maxLonValue setText:[GPKGSProperties getValueOfProperty:GPKGS_PROP_BOUNDING_BOX_DEFAULT_MAX_LONGITUDE]];
    self.latitudeValidator = [[GPKGSDecimalValidator alloc] initWithMinimumDouble:-90.0 andMaximumDouble:90.0];
    self.longitudeValidator = [[GPKGSDecimalValidator alloc] initWithMinimumDouble:-180.0 andMaximumDouble:180.0];
    [self.minLatValue setDelegate:self.latitudeValidator];
    [self.maxLatValue setDelegate:self.latitudeValidator];
    [self.minLonValue setDelegate:self.longitudeValidator];
    [self.maxLonValue setDelegate:self.longitudeValidator];
    self.boundingBoxes = [GPKGSProperties getArrayOfProperty:GPKGS_PROP_PRELOADED_BOUNDING_BOXES];
    self.geometryTypes = [GPKGSProperties getArrayOfProperty:GPKGS_PROP_EDIT_FEATURES_GEOMETRY_TYPES];
    [self.geometryTypeButton setTitle:[self.geometryTypes objectAtIndex:0] forState:UIControlStateNormal];
}

- (IBAction)cancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)createButton:(id)sender {
    
    @try {
        
        NSString * tableName = self.nameValue.text;
        if(tableName == nil || [tableName length] == 0){
            [NSException raise:@"Table Name" format:@"Table name is required"];
        }

        double minLat = [self.minLatValue.text doubleValue];
        double maxLat = [self.maxLatValue.text doubleValue];
        double minLon = [self.minLonValue.text doubleValue];
        double maxLon = [self.maxLonValue.text doubleValue];
        
        if (minLat > maxLat) {
            [NSException raise:@"Latitude Range" format:@"Min latitude can not be larger than max latitude"];
        }
        
        if (minLon > maxLon) {
            [NSException raise:@"Longitude Range" format:@"Min longitude can not be larger than max longitude"];
        }
        
        GPKGBoundingBox * boundingBox = [[GPKGBoundingBox alloc] initWithMinLongitudeDouble:minLon andMaxLongitudeDouble:maxLon andMinLatitudeDouble:minLat andMaxLatitudeDouble:maxLat];
        
        enum WKBGeometryType geometryType = [WKBGeometryTypes fromName:self.geometryTypeButton.titleLabel.text];
        
        GPKGGeometryColumns * geometryColumns = [[GPKGGeometryColumns alloc] init];
        [geometryColumns setTableName:tableName];
        [geometryColumns setColumnName:@"geom"];
        [geometryColumns setGeometryType:geometryType];
        [geometryColumns setZ:[NSNumber numberWithInt:0]];
        [geometryColumns setM:[NSNumber numberWithInt:0]];
        
        GPKGGeoPackage * geoPackage = [self.manager open:self.database.name];
        @try {
            [geoPackage createFeatureTableWithGeometryColumns:geometryColumns andBoundingBox:boundingBox andSrsId:[NSNumber numberWithInt:PROJ_EPSG_WORLD_GEODETIC_SYSTEM]];
            [self.delegate createFeaturesViewController:self createdFeatures:true withError:nil];
        }
        @finally {
            [geoPackage close];
        }
    }
    @catch (NSException *e) {
        [self.delegate createFeaturesViewController:self createdFeatures:false withError:[e description]];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch(alertView.tag){
            
        case TAG_GEOMETRY_TYPES:
            if(buttonIndex >= 0){
                if(buttonIndex < [self.geometryTypes count]){
                    NSString * geometryType = (NSString *)[self.geometryTypes objectAtIndex:buttonIndex];
                    [self.geometryTypeButton setTitle:geometryType forState:UIControlStateNormal];
                }
            }
            
            break;
        case TAG_BOUNDING_BOXES:
            if(buttonIndex >= 0){
                if(buttonIndex < [self.boundingBoxes count]){
                    NSDictionary * box = (NSDictionary *)[self.boundingBoxes objectAtIndex:buttonIndex];
                    [self.minLatValue setText:[box objectForKey:GPKGS_PROP_PRELOADED_BOUNDING_BOXES_MIN_LAT]];
                    [self.maxLatValue setText:[box objectForKey:GPKGS_PROP_PRELOADED_BOUNDING_BOXES_MAX_LAT]];
                    [self.minLonValue setText:[box objectForKey:GPKGS_PROP_PRELOADED_BOUNDING_BOXES_MIN_LON]];
                    [self.maxLonValue setText:[box objectForKey:GPKGS_PROP_PRELOADED_BOUNDING_BOXES_MAX_LON]];
                }
            }
            
            break;
    }
    
}

- (IBAction)preloadedLocations:(id)sender {
    NSMutableArray * boxes = [[NSMutableArray alloc] init];
    for(NSDictionary * box in self.boundingBoxes){
        [boxes addObject:[box objectForKey:GPKGS_PROP_PRELOADED_BOUNDING_BOXES_LABEL]];
    }
    
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_BOUNDING_BOX_PRELOADED_LABEL]
                          message:nil
                          delegate:self
                          cancelButtonTitle:nil
                          otherButtonTitles:nil];
    
    for (NSString *box in boxes) {
        [alert addButtonWithTitle:box];
    }
    alert.cancelButtonIndex = [alert addButtonWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]];
    
    alert.tag = TAG_BOUNDING_BOXES;
    
    [alert show];
}

- (IBAction)geometryType:(id)sender {
    
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_EDIT_FEATURES_GEOMETRY_TYPE_LABEL]
                          message:nil
                          delegate:self
                          cancelButtonTitle:nil
                          otherButtonTitles:nil];
    
    for (NSString *geometryType in self.geometryTypes) {
        [alert addButtonWithTitle:geometryType];
    }
    alert.cancelButtonIndex = [alert addButtonWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]];
    
    alert.tag = TAG_GEOMETRY_TYPES;
    
    [alert show];
    
}


@end
