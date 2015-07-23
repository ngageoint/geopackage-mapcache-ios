//
//  GPKGSLoadTilesViewController.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/23/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSLoadTilesViewController.h"
#import "GPKGSGenerateTilesViewController.h"
#import "GPKGSUtils.h"

NSString * const GPKGS_LOAD_TILES_SEG_GENERATE_TILES = @"generateTiles";

@interface GPKGSLoadTilesViewController ()

@end

@implementation GPKGSLoadTilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIToolbar *keyboardToolbar = [GPKGSUtils buildKeyboardDoneToolbarWithTarget:self andAction:@selector(doneButtonPressed)];
    
    self.urlTextField.inputAccessoryView = keyboardToolbar;
}

- (void) doneButtonPressed {
    [self.urlTextField resignFirstResponder];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([segue.identifier isEqualToString:GPKGS_LOAD_TILES_SEG_GENERATE_TILES])
    {
        GPKGSGenerateTilesViewController *generateTilesViewController = segue.destinationViewController;
        generateTilesViewController.data = self.data.generateTiles;
    }
}


@end
