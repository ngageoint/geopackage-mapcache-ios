//
//  GPKGSTileTable.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "MCTileTable.h"

@implementation MCTileTable

-(instancetype) initWithDatabase: (NSString *) database andName: (NSString *) name andCount: (int) count{
    self = [super initWithDatabase:database andName:name andCount:count];
    return self;
}

-(instancetype) initWithDatabase: (NSString *) database andName: (NSString *) name andCount: (int) count andMinZoom: (int) minZoom andMaxZoom: (int) maxZoom {
    self = [super initWithDatabase:database andName:name andCount:count];
    self.minZoom = minZoom;
    self.maxZoom = maxZoom;
    return self;
}

-(enum GPKGSTableType) getType{
    return GPKGS_TT_TILE;
}

@end
