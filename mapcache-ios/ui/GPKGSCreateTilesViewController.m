//
//  GPKGSCreateTilesViewController.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/23/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSCreateTilesViewController.h"
#import "GPKGSUtils.h"
#import "GPKGSLoadTilesViewController.h"

NSString * const GPKGS_CREATE_TILES_SEG_LOAD_TILES = @"loadTiles";

@interface GPKGSCreateTilesViewController ()

@end

@implementation GPKGSCreateTilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    UIToolbar *keyboardToolbar = [GPKGSUtils buildKeyboardDoneToolbarWithTarget:self andAction:@selector(doneButtonPressed)];
    
    self.nameTextField.inputAccessoryView = keyboardToolbar;
}

- (void) doneButtonPressed {
    [self.nameTextField resignFirstResponder];
}

- (IBAction)nameChanged:(id)sender {
    [self.data setName:self.nameTextField.text];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([segue.identifier isEqualToString:GPKGS_CREATE_TILES_SEG_LOAD_TILES])
    {
        GPKGSLoadTilesViewController *loadTilesViewController = segue.destinationViewController;
        loadTilesViewController.delegate = self;
        loadTilesViewController.data = self.data.loadTiles;
    }
}

- (void)loadTilesViewControllerUrlName:(NSString *) urlName{
    [self.data setName:urlName];
    [self.nameTextField setText:urlName];
}

@end
