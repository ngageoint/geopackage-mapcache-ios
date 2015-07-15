//
//  GPKGSFeatureOverlayTable.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSFeatureOverlayTable.h"

@implementation GPKGSFeatureOverlayTable

-(instancetype) initWithDatabase: (NSString *) database andName: (NSString *) name andFeatureTable: (NSString *) featureTable andGeometryType: (enum WKBGeometryType) geometryType andCount: (int) count{
    self = [super initWithDatabase:database andName:name andGeometryType:geometryType andCount:count];
    if(self != nil){
        self.featureTable = featureTable;
    }
    return self;
}

-(enum GPKGSTableType) getType{
    return GPKGS_TT_FEATURE_OVERLAY;
}

@end
