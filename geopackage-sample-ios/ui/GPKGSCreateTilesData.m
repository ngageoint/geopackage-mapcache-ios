//
//  GPKGSCreateTilesData.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/23/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSCreateTilesData.h"

@implementation GPKGSCreateTilesData

-(instancetype) init{
    self = [super init];
    if(self){
        self.loadTiles = [[GPKGSLoadTilesData alloc] init];
    }
    return self;
}

@end
