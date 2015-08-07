//
//  GPKGSLoadTilesData.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/23/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSLoadTilesData.h"

@implementation GPKGSLoadTilesData

-(instancetype) init{
    self = [super init];
    if(self){
        self.generateTiles = [[GPKGSGenerateTilesData alloc] init];
    }
    return self;
}

@end
