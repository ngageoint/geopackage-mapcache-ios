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


@interface NGADrawerCoordinator : NSObject <NGADrawerViewDelegate>
- (instancetype) initWithBackgroundViewController:(UIViewController *) viewController;
- (void) start;
- (void) pushDrawer:(NGADrawerViewController *) childViewController;
@end
