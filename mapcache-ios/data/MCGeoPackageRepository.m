//
//  MCGeoPackageRepository.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 3/2/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "MCGeoPackageRepository.h"

@implementation MCGeoPackageRepository

static MCGeoPackageRepository *sharedRepository = nil;

+ (MCGeoPackageRepository *) sharedRepository {
    if (sharedRepository == nil) {
        sharedRepository = [[self alloc] init];
    }
    
    return sharedRepository;
}


- (id)init {
    self = [super init];
    return self;
}



@end
