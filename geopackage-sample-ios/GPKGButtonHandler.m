//
//  GPKGButtonHandler.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/2/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGButtonHandler.h"

@implementation GPKGButtonHandler

-(IBAction)handleButton:(id)sender
{
    [[NSNotificationCenter defaultCenter] postNotificationName:@"notifyButtonPressed" object:self];
}

@end
