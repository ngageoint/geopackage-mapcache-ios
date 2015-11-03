//
//  GPKGSFeatureTilesDrawViewController.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/28/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSFeatureTilesDrawViewController.h"
#import "GPKGSUtils.h"
#import "GPKGUtils.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGSDecimalValidator.h"

@interface GPKGSFeatureTilesDrawViewController ()

@property (nonatomic, strong) GPKGSDecimalValidator * alphaValidator;
@property (nonatomic, strong) GPKGSDecimalValidator * decimalValidator;
@property (nonatomic, strong) NSNumberFormatter * numberFormatter;
@property (nonatomic, strong) NSArray * colors;

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
    
    self.colors = [GPKGSProperties getArrayOfProperty:GPKGS_PROP_FEATURE_TILES_DRAW_COLORS];
    NSMutableDictionary * colorNames = [[NSMutableDictionary alloc] initWithCapacity:self.colors.count];
    for(NSDictionary * color in self.colors){
        [colorNames setObject:color forKey:[color objectForKey:GPKGS_PROP_COLORS_NAME]];
    }
    
    if(self.data != nil){
        
        NSDictionary * pointColor = nil;
        if(self.data.pointColorName != nil){
            pointColor = [colorNames objectForKey:self.data.pointColorName];
        }else{
            pointColor = [colorNames objectForKey:[GPKGSProperties getValueOfProperty:GPKGS_PROP_FEATURE_TILES_DRAW_COLORS_DEFAULT_POINT]];
        }
        [self setColor:pointColor withTag:TAG_POINT_COLOR];
        
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
        
        NSDictionary * lineColor = nil;
        if(self.data.lineColorName != nil){
            lineColor = [colorNames objectForKey:self.data.lineColorName];
        }else{
            lineColor = [colorNames objectForKey:[GPKGSProperties getValueOfProperty:GPKGS_PROP_FEATURE_TILES_DRAW_COLORS_DEFAULT_LINE]];
        }
        [self setColor:lineColor withTag:TAG_LINE_COLOR];
        
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
        
        NSDictionary * polygonColor = nil;
        if(self.data.polygonColorName != nil){
            polygonColor = [colorNames objectForKey:self.data.polygonColorName];
        }else{
            polygonColor = [colorNames objectForKey:[GPKGSProperties getValueOfProperty:GPKGS_PROP_FEATURE_TILES_DRAW_COLORS_DEFAULT_POLYGON]];
        }
        [self setColor:polygonColor withTag:TAG_POLYGON_COLOR];
        
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
        
        NSDictionary * polygonFillColor = nil;
        if(self.data.polygonFillColorName != nil){
            polygonFillColor = [colorNames objectForKey:self.data.polygonFillColorName];
        }else{
            polygonFillColor = [colorNames objectForKey:[GPKGSProperties getValueOfProperty:GPKGS_PROP_FEATURE_TILES_DRAW_COLORS_DEFAULT_POLYGON_FILL]];
        }
        [self setColor:polygonFillColor withTag:TAG_POLYGON_FILL_COLOR];
        
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
    
        if(buttonIndex < [self.colors count]){
            NSDictionary * color = (NSDictionary *)[self.colors objectAtIndex:buttonIndex];
            [self setColor:color withTag:alertView.tag];
        }
    }
}

-(void) setColor: (NSDictionary *) color withTag: (NSInteger) tag{
    
    UIColor * createdColor = [GPKGUtils getColor:color];
    
    NSString * name = [color objectForKey:GPKGS_PROP_COLORS_NAME];
    
    switch(tag){
            
        case TAG_POINT_COLOR:
            [self.pointColorButton setTitle:name forState:UIControlStateNormal];
            [self.data setPointColor:createdColor];
            [self.data setPointColorName:name];
            break;
            
        case TAG_LINE_COLOR:
            [self.lineColorButton setTitle:name forState:UIControlStateNormal];
            [self.data setLineColor:createdColor];
            [self.data setLineColorName:name];
            break;
            
        case TAG_POLYGON_COLOR:
            [self.polygonColorButton setTitle:name forState:UIControlStateNormal];
            [self.data setPolygonColor:createdColor];
            [self.data setPolygonColorName:name];
            break;
            
        case TAG_POLYGON_FILL_COLOR:
            [self.polygonFillColorButton setTitle:name forState:UIControlStateNormal];
            [self.data setPolygonFillColor:createdColor];
            [self.data setPolygonFillColorName:name];
            break;
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
    
    NSMutableArray * options = [[NSMutableArray alloc] init];
    for(NSDictionary * color in self.colors){
        [options addObject:[color objectForKey:GPKGS_PROP_COLORS_NAME]];
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
