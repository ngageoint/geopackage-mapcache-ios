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
#import "GPKGSNewLayerViewController.h"


@protocol GPKGSCoordinatorDelegate <NSObject>
- (void) geoPackageCoordinatorCompletionHandler;
@end

@interface GPKGSCoordinator: NSObject <GPKGSOperationsDelegate>
- (instancetype) initWithNavigationController:(UINavigationController *) navigationController andDelegate:(id<GPKGSCoordinatorDelegate>)delegate andDatabase:(GPKGSDatabase *) database;
- (void) start;
@end
