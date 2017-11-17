//
//  GPKGSCoordinator.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/31/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPKGSGeopackageSingleViewController.h"
#import "GPKGSDatabase.h"

@interface GPKGSCoordinator : NSObject
- (instancetype) initWithNavigationController:(UINavigationController *) navigationController andGeoPackage:(GPKGSDatabase *) geoPackage;
- (void) start;
@end
