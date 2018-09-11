//
//  MCGeoPackageListCoordinator.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 8/27/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPKGGeoPackageManager.h>
#import "GPKGSDatabase.h"
#import "MCGeoPackageCoordinator.h"
#import "MCGeoPackageList.h"
#import "GPKGSFeatureOverlayTable.h"
#import "MCGeopackageSingleViewController.h"
#import "MCGeoPackageCoordinator.h"
#import "GPKGSDatabases.h"
#import "MCDownloadCoordinator.h"

@interface MCGeoPackageListCoordinator : NSObject <MCGeoPackageCoordinatorDelegate, MCGeoPacakageListViewDelegate, GPKGSDownloadCoordinatorDelegate>
@property (nonatomic, strong) id<NGADrawerViewDelegate> drawerViewDelegate;
- (void)start;
@end
