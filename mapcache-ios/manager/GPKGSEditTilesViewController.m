//
//  GPKGSEditTilesViewController.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/27/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSEditTilesViewController.h"
#import "GPKGSEditContentsViewController.h"
#import "MCUtils.h"
#import "MCDecimalValidator.h"
#import "MCLoadTilesTask.h"
#import "GPKGTileTableScaling.h"

NSString * const GPKGS_MANAGER_EDIT_TILES_SEG_EDIT_CONTENTS = @"editContents";

@interface GPKGSEditTilesViewController ()

@property (nonatomic, strong) GPKGSEditContentsData *data;
@property (nonatomic, strong) MCDecimalValidator * xAndYValidator;

@end

@implementation GPKGSEditTilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.xAndYValidator = [[MCDecimalValidator alloc] initWithMinimum:nil andMaximum:nil];
    [self.minYTextField setDelegate:self.xAndYValidator];
    [self.maxYTextField setDelegate:self.xAndYValidator];
    [self.minXTextField setDelegate:self.xAndYValidator];
    [self.maxXTextField setDelegate:self.xAndYValidator];
    
    UIToolbar *keyboardToolbar = [MCUtils buildKeyboardDoneToolbarWithTarget:self andAction:@selector(doneButtonPressed)];
    
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
        GPKGTileMatrixSetDao * tileMatrixSetDao = [geoPackage tileMatrixSetDao];
        GPKGContentsDao * contentsDao = [geoPackage contentsDao];
        GPKGTileMatrixSet * tileMatrixSet = (GPKGTileMatrixSet *)[tileMatrixSetDao queryForIdObject:self.table.name];
        GPKGContents * contents = [tileMatrixSetDao contents:tileMatrixSet];
        
        [contents setIdentifier:self.data.identifier];
        [contents setTheDescription:self.data.theDescription];
        [contents setMinY:self.data.minY];
        [contents setMaxY:self.data.maxY];
        [contents setMinX:self.data.minX];
        [contents setMaxX:self.data.maxX];
        [contents setLastChange:[NSDate date]];
        [contentsDao update:contents];
        
        NSDecimalNumber * minYNumber = nil;
        if(self.minYTextField.text.length > 0){
            double minY = [self.minYTextField.text doubleValue];
            minYNumber = [[NSDecimalNumber alloc] initWithDouble:minY];
        }
        [tileMatrixSet setMinY:minYNumber];
        
        NSDecimalNumber * maxYNumber = nil;
        if(self.maxYTextField.text.length > 0){
            double maxY = [self.maxYTextField.text doubleValue];
            maxYNumber = [[NSDecimalNumber alloc] initWithDouble:maxY];
        }
        [tileMatrixSet setMaxY:maxYNumber];
        
        NSDecimalNumber * minXNumber = nil;
        if(self.minXTextField.text.length > 0){
            double minX = [self.minXTextField.text doubleValue];
            minXNumber = [[NSDecimalNumber alloc] initWithDouble:minX];
        }
        [tileMatrixSet setMinX:minXNumber];
        
        NSDecimalNumber * maxXNumber = nil;
        if(self.maxXTextField.text.length > 0){
            double maxX = [self.maxXTextField.text doubleValue];
            maxXNumber = [[NSDecimalNumber alloc] initWithDouble:maxX];
        }
        [tileMatrixSet setMaxX:maxXNumber];

        [tileMatrixSetDao update:tileMatrixSet];
        
        GPKGTileScaling *scaling = [MCLoadTilesTask tileScaling];
        GPKGTileTableScaling *tileTableScaling = [[GPKGTileTableScaling alloc] initWithGeoPackage:geoPackage andTileMatrixSet:tileMatrixSet];
        if(scaling != nil){
            [tileTableScaling createOrUpdate:scaling];
        }else{
            [tileTableScaling delete];
        }
        
        if(self.delegate != nil){
            [self.delegate editTilesViewController:self tilesEdited:YES];
        }
    }
    @catch (NSException *e) {
        [MCUtils showMessageWithDelegate:self
                                   andTitle:@"Edit Tiles"
                                 andMessage:[NSString stringWithFormat:@"Error editing tiles table '%@' in database: '%@'\n\nError: %@", self.table.name, self.table.database, [e description]]];
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
        GPKGTileMatrixSetDao * tileMatrixSetDao = [geoPackage tileMatrixSetDao];
        GPKGTileMatrixSet * tileMatrixSet = (GPKGTileMatrixSet *)[tileMatrixSetDao queryForIdObject:self.table.name];
        GPKGContents * contents = [tileMatrixSetDao contents:tileMatrixSet];
        
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
