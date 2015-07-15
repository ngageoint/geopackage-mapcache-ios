//
//  GPKGSFeatureTable.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSFeatureTable.h"

@implementation GPKGSFeatureTable

-(instancetype) initWithDatabase: (NSString *) database andName: (NSString *) name andGeometryType: (enum WKBGeometryType) geometryType andCount: (int) count{
    self = [super initWithDatabase:database andName:name andCount:count];
    if(self != nil){
        self.geometryType = geometryType;
    }
    return self;
}

-(enum GPKGSTableType) getType{
    return GPKGS_TT_FEATURE;
}

@end
