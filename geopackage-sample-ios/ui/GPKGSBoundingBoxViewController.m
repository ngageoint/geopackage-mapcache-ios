//
//  GPKGSBoundingBoxViewController.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/20/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSBoundingBoxViewController.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGSDecimalValidator.h"

@interface GPKGSBoundingBoxViewController ()

@property (nonatomic, strong) NSArray * boundingBoxes;
@property (nonatomic, strong) GPKGSDecimalValidator * latitudeValidator;
@property (nonatomic, strong) GPKGSDecimalValidator * longitudeValidator;

@end

@implementation GPKGSBoundingBoxViewController

#define TAG_BOUNDING_BOXES 1

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.latitudeValidator = [[GPKGSDecimalValidator alloc] initWithMinimumDouble:-90.0 andMaximumDouble:90.0];
    self.longitudeValidator = [[GPKGSDecimalValidator alloc] initWithMinimumDouble:-180.0 andMaximumDouble:180.0];
    [self.minLatValue setDelegate:self.latitudeValidator];
    [self.maxLatValue setDelegate:self.latitudeValidator];
    [self.minLonValue setDelegate:self.longitudeValidator];
    [self.maxLonValue setDelegate:self.longitudeValidator];
    self.boundingBoxes = [GPKGSProperties getArrayOfProperty:GPKGS_PROP_PRELOADED_BOUNDING_BOXES];
    if(self.boundingBox == nil){
        [self.minLatValue setText:[GPKGSProperties getValueOfProperty:GPKGS_PROP_BOUNDING_BOX_DEFAULT_MIN_LATITUDE]];
        [self.maxLatValue setText:[GPKGSProperties getValueOfProperty:GPKGS_PROP_BOUNDING_BOX_DEFAULT_MAX_LATITUDE]];
        [self.minLonValue setText:[GPKGSProperties getValueOfProperty:GPKGS_PROP_BOUNDING_BOX_DEFAULT_MIN_LONGITUDE]];
        [self.maxLonValue setText:[GPKGSProperties getValueOfProperty:GPKGS_PROP_BOUNDING_BOX_DEFAULT_MAX_LONGITUDE]];
        self.boundingBox = [[GPKGBoundingBox alloc] initWithMinLongitudeDouble:-180.0 andMaxLongitudeDouble:180.0 andMinLatitudeDouble:-90.0 andMaxLatitudeDouble:90.0];
        [self updateBoundingBox];
    } else{
        [self.minLatValue setText:[self.boundingBox.minLatitude stringValue]];
        [self.maxLatValue setText:[self.boundingBox.maxLatitude stringValue]];
        [self.minLonValue setText:[self.boundingBox.minLongitude stringValue]];
        [self.maxLonValue setText:[self.boundingBox.maxLongitude stringValue]];
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch(alertView.tag){
            
        case TAG_BOUNDING_BOXES:
            if(buttonIndex >= 0){
                if(buttonIndex < [self.boundingBoxes count]){
                    NSDictionary * box = (NSDictionary *)[self.boundingBoxes objectAtIndex:buttonIndex];
                    [self.minLatValue setText:[box objectForKey:GPKGS_PROP_PRELOADED_BOUNDING_BOXES_MIN_LAT]];
                    [self.maxLatValue setText:[box objectForKey:GPKGS_PROP_PRELOADED_BOUNDING_BOXES_MAX_LAT]];
                    [self.minLonValue setText:[box objectForKey:GPKGS_PROP_PRELOADED_BOUNDING_BOXES_MIN_LON]];
                    [self.maxLonValue setText:[box objectForKey:GPKGS_PROP_PRELOADED_BOUNDING_BOXES_MAX_LON]];
                    [self updateBoundingBox];
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

- (IBAction)minLatChanged:(id)sender {
    double minLat = [self.minLatValue.text doubleValue];
    [self.boundingBox setMinLatitude:[[NSDecimalNumber alloc] initWithDouble:minLat]];
    [self boundingBoxUpdated];
}

- (IBAction)maxLatChanged:(id)sender {
    double maxLat = [self.maxLatValue.text doubleValue];
    [self.boundingBox setMaxLatitude:[[NSDecimalNumber alloc] initWithDouble:maxLat]];
    [self boundingBoxUpdated];
}

- (IBAction)minLonChanged:(id)sender {
    double minLon = [self.minLonValue.text doubleValue];
    [self.boundingBox setMinLongitude:[[NSDecimalNumber alloc] initWithDouble:minLon]];
    [self boundingBoxUpdated];
}

- (IBAction)maxLonChanged:(id)sender {
    double maxLon = [self.maxLonValue.text doubleValue];
    [self.boundingBox setMaxLongitude:[[NSDecimalNumber alloc] initWithDouble:maxLon]];
    [self boundingBoxUpdated];
}

-(void) updateBoundingBox{
    [self minLatChanged:self];
    [self maxLatChanged:self];
    [self minLonChanged:self];
    [self maxLonChanged:self];
    [self boundingBoxUpdated];
}

-(void) boundingBoxUpdated{
    [self.delegate boundingBoxViewController:self.boundingBox];
}

@end
