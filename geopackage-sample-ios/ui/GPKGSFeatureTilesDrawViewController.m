//
//  GPKGSFeatureTilesDrawViewController.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/28/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSFeatureTilesDrawViewController.h"
#import "GPKGSUtils.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGSDecimalValidator.h"

@interface GPKGSFeatureTilesDrawViewController ()

@property (nonatomic, strong) GPKGSDecimalValidator * alphaValidator;
@property (nonatomic, strong) GPKGSDecimalValidator * decimalValidator;
@property (nonatomic, strong) NSNumberFormatter * numberFormatter;

@end

@implementation GPKGSFeatureTilesDrawViewController

#define TAG_POINT_COLOR 1
#define TAG_LINE_COLOR 2
#define TAG_POLYGON_COLOR 3
#define TAG_POLYGON_FILL_COLOR 4

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.numberFormatter = [[NSNumberFormatter alloc] init];
    self.numberFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    
    self.alphaValidator = [[GPKGSDecimalValidator alloc] initWithMinimumInt:0 andMaximumInt:255];
    self.decimalValidator = [[GPKGSDecimalValidator alloc] initWithMinimum:[[NSDecimalNumber alloc] initWithDouble:0.0] andMaximum:nil];
    
    [self.pointAlphaTextField setDelegate:self.alphaValidator];
    [self.pointRadiusTextField setDelegate:self.decimalValidator];
    [self.lineAlphaTextField setDelegate:self.alphaValidator];
    [self.lineStrokeTextField setDelegate:self.decimalValidator];
    [self.polygonAlphaTextField setDelegate:self.alphaValidator];
    [self.polygonStrokeTextField setDelegate:self.decimalValidator];
    [self.polygonFillAlphaTextField setDelegate:self.alphaValidator];
    
    if(self.data != nil){
        
        [self.data setPointColor:[UIColor blackColor]];
        
        if(self.data.pointAlpha == nil){
            self.data.pointAlpha = [NSNumber numberWithInt:[self.pointAlphaTextField.text intValue]];
        }else{
            [self.pointAlphaTextField setText:[self.data.pointAlpha stringValue]];
        }
        
        if(self.data.pointRadius == nil){
            self.data.pointRadius = [[NSDecimalNumber alloc] initWithDouble:[self.pointRadiusTextField.text doubleValue]];
        }else{
            [self.pointRadiusTextField setText:[self.data.pointRadius stringValue]];
        }
        
        [self.data setLineColor:[UIColor blackColor]];
        
        if(self.data.lineAlpha == nil){
            self.data.lineAlpha = [NSNumber numberWithInt:[self.lineAlphaTextField.text intValue]];
        }else{
            [self.lineAlphaTextField setText:[self.data.lineAlpha stringValue]];
        }
        
        if(self.data.lineStroke == nil){
            self.data.lineStroke = [[NSDecimalNumber alloc] initWithDouble:[self.lineStrokeTextField.text doubleValue]];
        }else{
            [self.lineStrokeTextField setText:[self.data.lineStroke stringValue]];
        }
        
        [self.data setPolygonColor:[UIColor blackColor]];
        
        if(self.data.polygonAlpha == nil){
            self.data.polygonAlpha = [NSNumber numberWithInt:[self.polygonAlphaTextField.text intValue]];
        }else{
            [self.polygonAlphaTextField setText:[self.data.polygonAlpha stringValue]];
        }
        
        if(self.data.polygonStroke == nil){
            self.data.polygonStroke = [[NSDecimalNumber alloc] initWithDouble:[self.polygonStrokeTextField.text doubleValue]];
        }else{
            [self.polygonStrokeTextField setText:[self.data.polygonStroke stringValue]];
        }
        
        [self.polygonFillSwitch setOn:self.data.polygonFill];
        
        [self.data setPolygonFillColor:[UIColor blackColor]];
        
        if(self.data.polygonFillAlpha == nil){
            self.data.polygonFillAlpha = [NSNumber numberWithInt:[self.polygonFillAlphaTextField.text intValue]];
        }else{
            [self.polygonFillAlphaTextField setText:[self.data.polygonFillAlpha stringValue]];
        }
    }
    
    UIToolbar *keyboardToolbar = [GPKGSUtils buildKeyboardDoneToolbarWithTarget:self andAction:@selector(doneButtonPressed)];
    
    self.pointAlphaTextField.inputAccessoryView = keyboardToolbar;
    self.pointRadiusTextField.inputAccessoryView = keyboardToolbar;
    self.lineAlphaTextField.inputAccessoryView = keyboardToolbar;
    self.lineStrokeTextField.inputAccessoryView = keyboardToolbar;
    self.polygonAlphaTextField.inputAccessoryView = keyboardToolbar;
    self.polygonStrokeTextField.inputAccessoryView = keyboardToolbar;
    self.polygonFillAlphaTextField.inputAccessoryView = keyboardToolbar;
}

- (void) doneButtonPressed {
    [self.pointAlphaTextField resignFirstResponder];
    [self.pointRadiusTextField resignFirstResponder];
    [self.lineAlphaTextField resignFirstResponder];
    [self.lineStrokeTextField resignFirstResponder];
    [self.polygonAlphaTextField resignFirstResponder];
    [self.polygonStrokeTextField resignFirstResponder];
    [self.polygonFillAlphaTextField resignFirstResponder];
}

- (IBAction)pointAlphaChanged:(id)sender {
    int value = [self.pointAlphaTextField.text intValue];
    [self.data setPointAlpha:[[NSDecimalNumber alloc] initWithInt:value]];
}

- (IBAction)pointRadiusChanged:(id)sender {
    double value = [self.pointRadiusTextField.text doubleValue];
    [self.data setPointRadius:[[NSDecimalNumber alloc] initWithDouble:value]];
}

- (IBAction)lineAlphaChanged:(id)sender {
    int value = [self.lineAlphaTextField.text intValue];
    [self.data setLineAlpha:[[NSDecimalNumber alloc] initWithInt:value]];
}

- (IBAction)lineStrokeChanged:(id)sender {
    double value = [self.lineStrokeTextField.text doubleValue];
    [self.data setLineStroke:[[NSDecimalNumber alloc] initWithDouble:value]];
}

- (IBAction)polygonAlphaChanged:(id)sender {
    int value = [self.polygonAlphaTextField.text intValue];
    [self.data setPolygonAlpha:[[NSDecimalNumber alloc] initWithInt:value]];
}

- (IBAction)polygonStrokeChanged:(id)sender {
    double value = [self.polygonStrokeTextField.text doubleValue];
    [self.data setPolygonStroke:[[NSDecimalNumber alloc] initWithDouble:value]];
}

- (IBAction)polygonFillChanged:(id)sender {
    [self.data setPolygonFill:self.polygonFillSwitch.on];
}

- (IBAction)polygonFillAlphaChanged:(id)sender {
    int value = [self.polygonFillAlphaTextField.text intValue];
    [self.data setPolygonFillAlpha:[[NSDecimalNumber alloc] initWithInt:value]];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if(buttonIndex >= 0){
    
        NSArray * colors = [GPKGSProperties getArrayOfProperty:GPKGS_PROP_FEATURE_TILES_DRAW_COLORS];
        if(buttonIndex < [colors count]){
            UIColor * createdColor = nil;
            
            NSDictionary * color = (NSDictionary *)[colors objectAtIndex:buttonIndex];
            NSString * name = [color objectForKey:GPKGS_PROP_FEATURE_TILES_DRAW_COLORS_NAME];
            
            NSNumber * alpha = [color objectForKey:GPKGS_PROP_FEATURE_TILES_DRAW_COLORS_ALPHA];
            NSNumber * white = [color objectForKey:GPKGS_PROP_FEATURE_TILES_DRAW_COLORS_WHITE];
            if(white != nil){
                createdColor = [UIColor colorWithWhite:[white doubleValue] alpha:[alpha doubleValue]];
            }else{
                NSNumber * red = [color objectForKey:GPKGS_PROP_FEATURE_TILES_DRAW_COLORS_RED];
                NSNumber * green = [color objectForKey:GPKGS_PROP_FEATURE_TILES_DRAW_COLORS_GREEN];
                NSNumber * blue = [color objectForKey:GPKGS_PROP_FEATURE_TILES_DRAW_COLORS_BLUE];
                createdColor = [UIColor colorWithRed:[red doubleValue] green:[green doubleValue] blue:[blue doubleValue] alpha:[alpha doubleValue]];
            }
        
            switch(alertView.tag){
                    
                case TAG_POINT_COLOR:
                    [self.pointColorButton setTitle:name forState:UIControlStateNormal];
                    [self.data setPointColor:createdColor];
                    break;
                    
                case TAG_LINE_COLOR:
                    [self.lineColorButton setTitle:name forState:UIControlStateNormal];
                    [self.data setLineColor:createdColor];
                    break;
                    
                case TAG_POLYGON_COLOR:
                    [self.polygonColorButton setTitle:name forState:UIControlStateNormal];
                    [self.data setPolygonColor:createdColor];
                    break;
                    
                case TAG_POLYGON_FILL_COLOR:
                    [self.polygonFillColorButton setTitle:name forState:UIControlStateNormal];
                    [self.data setPolygonFillColor:createdColor];
                    break;
            }
            
        }
    }
}

- (IBAction)pointColorButton:(id)sender {
    
    UIAlertView *alert = [self buildColorAlertViewWithTitle: [GPKGSProperties getValueOfProperty:GPKGS_PROP_FEATURE_TILES_DRAW_POINT_COLOR_LABEL]];
    alert.tag = TAG_POINT_COLOR;
    [alert show];
}

- (IBAction)lineColorButton:(id)sender {
    UIAlertView *alert = [self buildColorAlertViewWithTitle: [GPKGSProperties getValueOfProperty:GPKGS_PROP_FEATURE_TILES_DRAW_LINE_COLOR_LABEL]];
    alert.tag = TAG_LINE_COLOR;
    [alert show];
}

- (IBAction)polygonColorButton:(id)sender {
    UIAlertView *alert = [self buildColorAlertViewWithTitle: [GPKGSProperties getValueOfProperty:GPKGS_PROP_FEATURE_TILES_DRAW_POLYGON_COLOR_LABEL]];
    alert.tag = TAG_POLYGON_COLOR;
    [alert show];
}

- (IBAction)polygonFillColorButton:(id)sender {
    UIAlertView *alert = [self buildColorAlertViewWithTitle: [GPKGSProperties getValueOfProperty:GPKGS_PROP_FEATURE_TILES_DRAW_POLYGON_FILL_COLOR_LABEL]];
    alert.tag = TAG_POLYGON_FILL_COLOR;
    [alert show];
}

- (UIAlertView *)buildColorAlertViewWithTitle: (NSString *) title{
    
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
    
    NSMutableArray * options = [[NSMutableArray alloc] init];
    NSArray * colors = [GPKGSProperties getArrayOfProperty:GPKGS_PROP_FEATURE_TILES_DRAW_COLORS];
    for(NSDictionary * color in colors){
        [options addObject:[color objectForKey:GPKGS_PROP_FEATURE_TILES_DRAW_COLORS_NAME]];
    }
    
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:title
                          message:nil
                          delegate:self
                          cancelButtonTitle:nil
                          otherButtonTitles:nil];
    
    for (NSString *option in options) {
        [alert addButtonWithTitle:option];
    }
    alert.cancelButtonIndex = [alert addButtonWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]];
    
    return alert;
}

@end
