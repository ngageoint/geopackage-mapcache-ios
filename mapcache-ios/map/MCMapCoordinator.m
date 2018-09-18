//
//  MCMapCoordinator.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 9/12/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCMapCoordinator.h"
#import "MCMapViewController.h"

@interface MCMapCoordinator ()
@property (nonatomic, strong) MCMapViewController *mcMapViewController;
@end

@implementation MCMapCoordinator

- (instancetype) initWithMapViewController:(MCMapViewController *) mapViewController {
    self = [super init];
    self.mcMapViewController = mapViewController;
    
    return self;
}


#pragma mark - MCMapDelegate methods
- (void) updateMapLayers {
    NSLog(@"In MapCoordinator, going to update layers");
    [self.mcMapViewController updateInBackgroundWithZoom:NO];
}


- (void) toggleGeoPackage:(GPKGSDatabase *) geoPackage {
    NSLog(@"In MCMapCoordinator, going to toggle %@", geoPackage.name);
}

@end
