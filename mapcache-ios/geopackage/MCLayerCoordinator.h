//
//  MCLayerCoordinator.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 7/17/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPKGGeoPackageManager.h>
#import "GPKGGeoPackageFactory.h"
#import "MCLayerViewController.h"
#import "MCFeatureLayerOperationsCell.h"
#import "MCTileLayerOperationsCell.h"
#import "GPKGSDatabase.h"
#import "GPKGUserDao.h"
#import "GPKGSUtils.h"
#import "GPKGSProperties.h"


@interface MCLayerCoordinator : NSObject <MCLayerOperationsDelegate>
- (instancetype) initWithNavigationController:(UINavigationController *) navigationController andDatabase:(GPKGSDatabase *) database
                                       andDao:(GPKGUserDao *) dao;
- (void) start;
@end
