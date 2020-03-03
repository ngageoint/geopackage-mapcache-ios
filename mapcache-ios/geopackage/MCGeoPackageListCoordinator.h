//
//  MCGeoPackageListCoordinator.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 8/27/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPKGGeoPackageManager.h>
#import "MCDatabase.h"
#import "MCGeoPackageCoordinator.h"
#import "MCGeoPackageList.h"
#import "MCFeatureOverlayTable.h"
#import "MCGeopackageSingleViewController.h"
#import "MCGeoPackageCoordinator.h"
#import "MCDatabases.h"
#import "MCDownloadCoordinator.h"
#import "MCTable.h"
#import "MCMapCoordinator.h"
#import "MCConstants.h"
#import "GPKGGeoPackageCache.h"
#import "MCCreateGeoPacakgeViewController.h"


@protocol MCMapDelegate;
@protocol MCGeoPackageCoordinatorDelegate;

@interface MCGeoPackageListCoordinator : NSObject <MCGeoPackageCoordinatorDelegate, MCGeoPacakageListViewDelegate, GPKGSDownloadCoordinatorDelegate, MCCreateGeoPackageDelegate>
@property (nonatomic, strong) id<NGADrawerViewDelegate> drawerViewDelegate;
@property (nonatomic, strong) id<MCMapDelegate> mcMapDelegate;
- (void)start;
@end
