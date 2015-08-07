//
//  GPKGSEditTileOverlayData.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/29/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSEditTileOverlayData.h"

@implementation GPKGSEditTileOverlayData

-(instancetype) init{
    self = [super init];
    if(self){
        self.featureTilesDraw = [[GPKGSFeatureTilesDrawData alloc] init];
    }
    return self;
}

@end
