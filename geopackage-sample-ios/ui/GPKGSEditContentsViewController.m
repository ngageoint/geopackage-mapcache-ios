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
    double value = [self.minYTextField.text doubleValue];
    [self.data setMinY:[[NSDecimalNumber alloc] initWithDouble:value]];
}

- (IBAction)maxYChanged:(id)sender {
    double value = [self.maxYTextField.text doubleValue];
    [self.data setMaxY:[[NSDecimalNumber alloc] initWithDouble:value]];
}

- (IBAction)minXChanged:(id)sender {
    double value = [self.minXTextField.text doubleValue];
    [self.data setMinX:[[NSDecimalNumber alloc] initWithDouble:value]];
}

- (IBAction)maxXChanged:(id)sender {
    double value = [self.maxXTextField.text doubleValue];
    [self.data setMaxX:[[NSDecimalNumber alloc] initWithDouble:value]];
}

@end
