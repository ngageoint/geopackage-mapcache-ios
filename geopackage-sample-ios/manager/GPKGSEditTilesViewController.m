//
//  GPKGSEditTilesViewController.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/27/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSEditTilesViewController.h"
#import "GPKGSEditContentsViewController.h"
#import "GPKGSUtils.h"

NSString * const GPKGS_MANAGER_EDIT_TILES_SEG_EDIT_CONTENTS = @"editContents";

@interface GPKGSEditTilesViewController ()

@property (nonatomic, strong) GPKGSEditContentsData *data;

@end

@implementation GPKGSEditTilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIToolbar *keyboardToolbar = [GPKGSUtils buildKeyboardDoneToolbarWithTarget:self andAction:@selector(doneButtonPressed)];
    
    self.minYTextField.inputAccessoryView = keyboardToolbar;
    self.maxYTextField.inputAccessoryView = keyboardToolbar;
    self.minXTextField.inputAccessoryView = keyboardToolbar;
    self.maxXTextField.inputAccessoryView = keyboardToolbar;
}

- (void) doneButtonPressed {
    [self.minYTextField resignFirstResponder];
    [self.maxYTextField resignFirstResponder];
    [self.minXTextField resignFirstResponder];
    [self.maxXTextField resignFirstResponder];
}

- (IBAction)cancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)editButton:(id)sender {
    
    GPKGGeoPackage * geoPackage = [self.manager open:self.table.database];
    @try {
        GPKGTileMatrixSetDao * tileMatrixSetDao = [geoPackage getTileMatrixSetDao];
        GPKGContentsDao * contentsDao = [geoPackage getContentsDao];
        GPKGTileMatrixSet * tileMatrixSet = (GPKGTileMatrixSet *)[tileMatrixSetDao queryForIdObject:self.table.name];
        GPKGContents * contents = [tileMatrixSetDao getContents:tileMatrixSet];
        
        [contents setIdentifier:self.data.identifier];
        [contents setTheDescription:self.data.theDescription];
        [contents setMinY:self.data.minY];
        [contents setMaxY:self.data.maxY];
        [contents setMinX:self.data.minX];
        [contents setMaxX:self.data.maxX];
        [contents setLastChange:[NSDate date]];
        [contentsDao update:contents];
        
        double minY = [self.minYTextField.text doubleValue];
        [tileMatrixSet setMinY:[[NSDecimalNumber alloc] initWithDouble:minY]];
        double maxY = [self.maxYTextField.text doubleValue];
        [tileMatrixSet setMaxY:[[NSDecimalNumber alloc] initWithDouble:maxY]];
        double minX = [self.minXTextField.text doubleValue];
        [tileMatrixSet setMinX:[[NSDecimalNumber alloc] initWithDouble:minX]];
        double maxX = [self.maxXTextField.text doubleValue];
        [tileMatrixSet setMaxX:[[NSDecimalNumber alloc] initWithDouble:maxX]];
        [tileMatrixSetDao update:tileMatrixSet];
    }
    @finally {
        [geoPackage close];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([segue.identifier isEqualToString:GPKGS_MANAGER_EDIT_TILES_SEG_EDIT_CONTENTS])
    {
        [self setFields];
        GPKGSEditContentsViewController *editContentsViewController = segue.destinationViewController;
        editContentsViewController.data = self.data;
    }
}

-(void) setFields{
    
    self.data = [[GPKGSEditContentsData alloc] init];
    
    GPKGGeoPackage * geoPackage = [self.manager open:self.table.database];
    @try {
        GPKGTileMatrixSetDao * tileMatrixSetDao = [geoPackage getTileMatrixSetDao];
        GPKGTileMatrixSet * tileMatrixSet = (GPKGTileMatrixSet *)[tileMatrixSetDao queryForIdObject:self.table.name];
        GPKGContents * contents = [tileMatrixSetDao getContents:tileMatrixSet];
        
        [self.data setIdentifier:contents.identifier];
        [self.data setTheDescription:contents.theDescription];
        [self.data setMinY:contents.minY];
        [self.data setMaxY:contents.maxY];
        [self.data setMinX:contents.minX];
        [self.data setMaxX:contents.maxX];
        
        [self.minYTextField setText:[tileMatrixSet.minY stringValue]];
        [self.maxYTextField setText:[tileMatrixSet.maxY stringValue]];
        [self.minXTextField setText:[tileMatrixSet.minX stringValue]];
        [self.maxXTextField setText:[tileMatrixSet.maxX stringValue]];
    }
    @finally {
        [geoPackage close];
    }
    
}

@end
