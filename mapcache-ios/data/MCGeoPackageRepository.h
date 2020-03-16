//
//  MCGeoPackageRepository.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 3/2/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPKGGeoPackageManager.h>
#import "GPKGGeoPackageFactory.h"
#import "GPKGGeoPackageCache.h"
#import "MCDatabase.h"
#import "MCDatabases.h"
#import "MCFeatureTable.h"
#import "MCTileTable.h"
#import "MCFeatureOverlayTable.h"


NS_ASSUME_NONNULL_BEGIN

@interface MCGeoPackageRepository : NSObject
+ (MCGeoPackageRepository *) sharedRepository;
- (NSMutableArray *)databaseList;
- (NSMutableArray *)refreshDatabaseList;
@end

NS_ASSUME_NONNULL_END
