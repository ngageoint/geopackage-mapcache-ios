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
        
        // TODO points color
        
        if(self.data.pointAlpha == nil){
            self.data.pointAlpha = [NSNumber numberWithInt:[self.pointAlphaTextField.text intValue]];
        }else{
            [self.pointAlphaTextField setText:[self.data.pointAlpha stringValue]];
        }
        
        // TODO set values
        
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

@end
