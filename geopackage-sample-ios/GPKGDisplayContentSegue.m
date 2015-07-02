//
//  GPKGDisplayContentSegue.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/2/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGDisplayContentSegue.h"
#import "GPKGMenuViewController.h"
#import "GPKGMenuDrawerViewController.h"

@implementation GPKGDisplayContentSegue

-(void)perform
{
    GPKGMenuDrawerViewController* menuDrawerViewController = ((GPKGMenuViewController*)self.sourceViewController).menuDrawerViewController;
    menuDrawerViewController.content = self.destinationViewController;
}

@end
