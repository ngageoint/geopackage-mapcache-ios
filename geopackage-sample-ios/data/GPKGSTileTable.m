//
//  GPKGSTileTable.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSTileTable.h"

@implementation GPKGSTileTable

-(instancetype) initWithDatabase: (NSString *) database andName: (NSString *) name andCount: (int) count{
    self = [super initWithDatabase:database andName:name andCount:count];
    return self;
}

-(enum GPKGSTableType) getType{
    return GPKGS_TT_TILE;
}

@end
