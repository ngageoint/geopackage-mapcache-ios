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
#import "MCDatabase.h"
#import "GPKGUserDao.h"
#import "MCUtils.h"
#import "MCProperties.h"


@interface MCLayerCoordinator : NSObject <MCLayerOperationsDelegate>
- (instancetype) initWithNavigationController:(UINavigationController *) navigationController andDatabase:(MCDatabase *) database
                                       andDao:(GPKGUserDao *) dao;
- (void) start;
@end
