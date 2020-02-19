//
//  GPKGSGenerateTilesData.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/23/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSGenerateTilesData.h"

@implementation GPKGSGenerateTilesData

-(instancetype) init{
    self = [super init];
    if(self){
        self.compressFormat = GPKG_CF_NONE;
        self.xyzTiles = false;
        self.setZooms = true;
    }
    return self;
}

@end
