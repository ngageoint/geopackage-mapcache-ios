//
//  GPKGSFeatureTilesDrawViewController.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/28/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSFeatureTilesDrawViewController.h"
#import "GPKGSUtils.h"

@implementation GPKGSFeatureTilesDrawViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // TODO number formatters?
    
    if(self.data != nil){
        
        // TODO set values
        
    }
    
    UIToolbar *keyboardToolbar = [GPKGSUtils buildKeyboardDoneToolbarWithTarget:self andAction:@selector(doneButtonPressed)];
    
    // TODO add keyboard toolbar to text fields
}

- (void) doneButtonPressed {
    // resign keyboards
}

@end
