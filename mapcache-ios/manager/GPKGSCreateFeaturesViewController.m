//
//  GPKGSCreateFeaturesViewController.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/20/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSCreateFeaturesViewController.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGSDecimalValidator.h"
#import "GPKGGeoPackage.h"
#import "PROJProjectionConstants.h"
#import "GPKGSBoundingBoxViewController.h"
#import "GPKGSUtils.h"

NSString * const GPKGS_CREATE_FEATURES_SEG_BOUNDING_BOX = @"boundingBox";

@interface GPKGSCreateFeaturesViewController ()

@property (nonatomic, strong) NSArray * geometryTypes;
@property (nonatomic, strong) GPKGBoundingBox * boundingBox;

@end

@implementation GPKGSCreateFeaturesViewController

#define TAG_GEOMETRY_TYPES 1


- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.databaseValue setText:self.database.name];
    self.geometryTypes = [GPKGSProperties getArrayOfProperty:GPKGS_PROP_EDIT_FEATURES_GEOMETRY_TYPES];
    [self.geometryTypeButton setTitle:[self.geometryTypes objectAtIndex:0] forState:UIControlStateNormal];

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
            [NSException raise:@"Table Name" format:@"Table name is required"];
        }
        
        if ([self.boundingBox.minLatitude doubleValue] > [self.boundingBox.maxLatitude doubleValue]) {
            [NSException raise:@"Latitude Range" format:@"Min latitude can not be larger than max latitude"];
        }
        
        if ([self.boundingBox.minLongitude doubleValue] > [self.boundingBox.maxLongitude doubleValue]) {
            [NSException raise:@"Longitude Range" format:@"Min longitude can not be larger than max longitude"];
        }
        
        enum SFGeometryType geometryType = [SFGeometryTypes fromName:self.geometryTypeButton.titleLabel.text];
        
        GPKGGeometryColumns * geometryColumns = [[GPKGGeometryColumns alloc] init];
        [geometryColumns setTableName:tableName];
        [geometryColumns setColumnName:@"geom"];
        [geometryColumns setGeometryType:geometryType];
        [geometryColumns setZ:[NSNumber numberWithInt:0]];
        [geometryColumns setM:[NSNumber numberWithInt:0]];
        
        GPKGGeoPackage * geoPackage = [self.manager open:self.database.name];
        @try {
            GPKGSpatialReferenceSystem *srs = [[geoPackage spatialReferenceSystemDao] srsWithEpsg:[NSNumber numberWithInt:PROJ_EPSG_WORLD_GEODETIC_SYSTEM]];
            [geometryColumns setSrs:srs];
            [geoPackage createFeatureTableWithMetadata:[GPKGFeatureTableMetadata createWithGeometryColumns:geometryColumns andBoundingBox:self.boundingBox]];
            if(self.delegate != nil){
                [self.delegate createFeaturesViewController:self createdFeatures:true withError:nil];
            }
        }
        @finally {
            [geoPackage close];
        }
    }
    @catch (NSException *e) {
        if(self.delegate != nil){
            [self.delegate createFeaturesViewController:self createdFeatures:false withError:[e description]];
        }
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
    }
    
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

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([segue.identifier isEqualToString:GPKGS_CREATE_FEATURES_SEG_BOUNDING_BOX])
    {
        GPKGSBoundingBoxViewController *boundingBoxViewController = segue.destinationViewController;
        boundingBoxViewController.delegate = self;
    }
}

- (void)boundingBoxViewController:(GPKGBoundingBox *) boundingBox{
    self.boundingBox = boundingBox;
}

@end
