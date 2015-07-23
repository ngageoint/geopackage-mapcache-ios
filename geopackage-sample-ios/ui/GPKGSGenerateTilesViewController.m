//
//  GPKGSGenerateTilesViewController.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/23/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSGenerateTilesViewController.h"
#import "GPKGSBoundingBoxViewController.h"
#import "GPKGSUtils.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGSDecimalValidator.h"

NSString * const GPKGS_GENERATE_TILES_SEG_BOUNDING_BOX = @"boundingBox";

@interface GPKGSGenerateTilesViewController ()

@property (nonatomic, strong) GPKGSDecimalValidator * zoomValidator;
@property (nonatomic, strong) GPKGSDecimalValidator * percentageValidator;
@property (nonatomic, strong) NSNumberFormatter * numberFormatter;

@end

@implementation GPKGSGenerateTilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.numberFormatter = [[NSNumberFormatter alloc] init];
    self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    NSNumber * minZoomValidation = [GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_LOAD_TILES_MIN_ZOOM_DEFAULT];
    NSNumber * maxZoomValidation = [GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_LOAD_TILES_MAX_ZOOM_DEFAULT];
    self.zoomValidator = [[GPKGSDecimalValidator alloc] initWithMinimumNumber:minZoomValidation andMaximumNumber:maxZoomValidation];
    self.percentageValidator = [[GPKGSDecimalValidator alloc] initWithMinimumInt:0 andMaximumInt:100];
    
    [self.minZoomTextField setDelegate:self.zoomValidator];
    [self.maxZoomTextField setDelegate:self.zoomValidator];
    [self.compressQualityTextField setDelegate:self.percentageValidator];
    [self.compressScaleTextField setDelegate:self.percentageValidator];
    
    if(self.data != nil){
        
        if(self.data.minZoom == nil){
            self.data.minZoom = [GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_LOAD_TILES_DEFAULT_MIN_ZOOM_DEFAULT];
        }
        [self.minZoomTextField setText:[self.data.minZoom stringValue]];
        
        if(self.data.maxZoom == nil){
            self.data.maxZoom = [GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_LOAD_TILES_DEFAULT_MAX_ZOOM_DEFAULT];
        }
        [self.maxZoomTextField setText:[self.data.maxZoom stringValue]];
        
        if(self.data.compressQuality == nil){
            self.data.compressQuality = [GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_LOAD_TILES_COMPRESS_QUALITY_DEFAULT];
        }
        [self.compressQualityTextField setText:[self.data.compressQuality stringValue]];
        
        if(self.data.compressScale == nil){
            self.data.compressScale = [GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_LOAD_TILES_COMPRESS_SCALE_DEFAULT];
        }
        [self.compressScaleTextField setText:[self.data.compressScale stringValue]];
        
    }
    
    UIToolbar *keyboardToolbar = [GPKGSUtils buildKeyboardDoneToolbarWithTarget:self andAction:@selector(doneButtonPressed)];
    
    self.minZoomTextField.inputAccessoryView = keyboardToolbar;
    self.maxZoomTextField.inputAccessoryView = keyboardToolbar;
    self.compressQualityTextField.inputAccessoryView = keyboardToolbar;
    self.compressScaleTextField.inputAccessoryView = keyboardToolbar;
}

- (IBAction)minZoomChanged:(id)sender {
    self.data.minZoom = [self.numberFormatter numberFromString:self.minZoomTextField.text];
}

- (IBAction)maxZoomChanged:(id)sender {
    self.data.maxZoom = [self.numberFormatter numberFromString:self.maxZoomTextField.text];
}

- (IBAction)compressFormatChanged:(id)sender {
    switch(self.compressFormatSegmentedControl.selectedSegmentIndex){
        case 0:
            self.data.compressFormat = GPKG_CF_NONE;
            break;
        case 1:
            self.data.compressFormat = GPKG_CF_JPEG;
            break;
        case 2:
            self.data.compressFormat = GPKG_CF_PNG;
            break;
    }
}

- (IBAction)compressQualityChanged:(id)sender {
    self.data.compressQuality = [self.numberFormatter numberFromString:self.compressQualityTextField.text];
}

- (IBAction)compressScaleChanged:(id)sender {
    self.data.compressScale = [self.numberFormatter numberFromString:self.compressScaleTextField.text];
}

- (IBAction)tileFormatChanged:(id)sender {
    switch (self.tileFormatSegmentedControl.selectedSegmentIndex){
        case 0:
            self.data.standardWebMercatorFormat = false;
            break;
        case 1:
            self.data.standardWebMercatorFormat = true;
            break;
    }
}

- (void) doneButtonPressed {
    [self.minZoomTextField resignFirstResponder];
    [self.maxZoomTextField resignFirstResponder];
    [self.compressQualityTextField resignFirstResponder];
    [self.compressScaleTextField resignFirstResponder];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([segue.identifier isEqualToString:GPKGS_GENERATE_TILES_SEG_BOUNDING_BOX])
    {
        GPKGSBoundingBoxViewController *boundingBoxViewController = segue.destinationViewController;
        boundingBoxViewController.delegate = self;
        if(self.data.boundingBox != nil){
            boundingBoxViewController.boundingBox = self.data.boundingBox;
        }
    }
}

- (void)boundingBoxViewController:(GPKGBoundingBox *) boundingBox{
    self.data.boundingBox = boundingBox;
}

@end
