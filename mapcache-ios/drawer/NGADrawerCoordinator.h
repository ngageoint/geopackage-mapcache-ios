//
//  MCDrawerCoordinator.h
//  MapDrawer
//
//  Created by Tyler Burgett on 8/20/18.
//  Copyright © 2018 GeoPackage. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCGeoPackageList.h"
#import "NGADrawerViewController.h"
#import "MCGeoPackageListCoordinator.h"
#import "MCMapCoordinator.h"
#import "MCGeoPackageCoordinator.h"

@protocol MCMapDelegate;
@interface NGADrawerCoordinator : NSObject <NGADrawerViewDelegate>
- (instancetype) initWithBackgroundViewController:(UIViewController *) viewController andMCMapDelegate:(id<MCMapDelegate>) mcMapDelegate;
- (MCGeoPackageListCoordinator*) start;
- (void) pushDrawer:(NGADrawerViewController *) childViewController;
@property (nonatomic, strong) id<MCMapDelegate> mcMapDelegate;
@end
