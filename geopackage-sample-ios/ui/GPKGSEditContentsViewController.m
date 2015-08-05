//
//  GPKGSEditContentsViewController.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/27/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSEditContentsViewController.h"
#import "GPKGSDecimalValidator.h"
#import "GPKGSUtils.h"

@interface GPKGSEditContentsViewController ()

@property (nonatomic, strong) GPKGSDecimalValidator * xAndYValidator;

@end

@implementation GPKGSEditContentsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.xAndYValidator = [[GPKGSDecimalValidator alloc] initWithMinimum:nil andMaximum:nil];
    [self.minYTextField setDelegate:self.xAndYValidator];
    [self.maxYTextField setDelegate:self.xAndYValidator];
    [self.minXTextField setDelegate:self.xAndYValidator];
    [self.maxXTextField setDelegate:self.xAndYValidator];
    
    [self.identifierTextField setText:self.data.identifier];
    [self.descriptionTextField setText:self.data.theDescription];
    if(self.data.minY != nil){
        [self.minYTextField setText:[self.data.minY stringValue]];
    }
    if(self.data.maxY != nil){
        [self.maxYTextField setText:[self.data.maxY stringValue]];
    }
    if(self.data.minX != nil){
        [self.minXTextField setText:[self.data.minX stringValue]];
    }
    if(self.data.maxX != nil){
        [self.maxXTextField setText:[self.data.maxX stringValue]];
    }
    
    UIToolbar *keyboardToolbar = [GPKGSUtils buildKeyboardDoneToolbarWithTarget:self andAction:@selector(doneButtonPressed)];
    
    self.identifierTextField.inputAccessoryView = keyboardToolbar;
    self.descriptionTextField.inputAccessoryView = keyboardToolbar;
    self.minYTextField.inputAccessoryView = keyboardToolbar;
    self.maxYTextField.inputAccessoryView = keyboardToolbar;
    self.minXTextField.inputAccessoryView = keyboardToolbar;
    self.maxXTextField.inputAccessoryView = keyboardToolbar;
}

- (void) doneButtonPressed {
    [self.identifierTextField resignFirstResponder];
    [self.descriptionTextField resignFirstResponder];
    [self.minYTextField resignFirstResponder];
    [self.maxYTextField resignFirstResponder];
    [self.minXTextField resignFirstResponder];
    [self.maxXTextField resignFirstResponder];
}

- (IBAction)identifierChanged:(id)sender {
    [self.data setIdentifier:self.identifierTextField.text];
}

- (IBAction)descriptionChanged:(id)sender {
    [self.data setTheDescription:self.descriptionTextField.text];
}

- (IBAction)minYChanged:(id)sender {
    NSDecimalNumber * minYNumber = nil;
    if(self.minYTextField.text.length > 0){
        double minY = [self.minYTextField.text doubleValue];
        minYNumber = [[NSDecimalNumber alloc] initWithDouble:minY];
    }
    [self.data setMinY:minYNumber];
}

- (IBAction)maxYChanged:(id)sender {
    NSDecimalNumber * maxYNumber = nil;
    if(self.maxYTextField.text.length > 0){
        double maxY = [self.maxYTextField.text doubleValue];
        maxYNumber = [[NSDecimalNumber alloc] initWithDouble:maxY];
    }
    [self.data setMaxY:maxYNumber];
}

- (IBAction)minXChanged:(id)sender {
    NSDecimalNumber * minXNumber = nil;
    if(self.minXTextField.text.length > 0){
        double minX = [self.minXTextField.text doubleValue];
        minXNumber = [[NSDecimalNumber alloc] initWithDouble:minX];
    }
    [self.data setMinX:minXNumber];
}

- (IBAction)maxXChanged:(id)sender {
    NSDecimalNumber * maxXNumber = nil;
    if(self.maxXTextField.text.length > 0){
        double maxX = [self.maxXTextField.text doubleValue];
        maxXNumber = [[NSDecimalNumber alloc] initWithDouble:maxX];
    }
    [self.data setMaxX:maxXNumber];
}

@end
