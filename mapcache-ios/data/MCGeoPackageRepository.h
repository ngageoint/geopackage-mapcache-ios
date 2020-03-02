//
//  MCGeoPackageRepository.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 3/2/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <GPKGGeoPackageManager.h>


NS_ASSUME_NONNULL_BEGIN

@interface MCGeoPackageRepository : NSObject
+ (MCGeoPackageRepository *) sharedRepository;
@end

NS_ASSUME_NONNULL_END
