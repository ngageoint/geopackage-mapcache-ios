//
//  GPKGSFeatureTable.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSFeatureTable.h"

NSString * const GPKGS_FEATURE_TABLE_GEOMETRY_TYPE = @"geometry_type";

@implementation GPKGSFeatureTable

-(instancetype) initWithDatabase: (NSString *) database andName: (NSString *) name andGeometryType: (enum SFGeometryType) geometryType andCount: (int) count{
    self = [super initWithDatabase:database andName:name andCount:count];
    if(self != nil){
        self.geometryType = geometryType;
    }
    return self;
}

-(instancetype) initWithValues: (NSDictionary *) values{
    self = [super initWithValues:values];
    if(self != nil){
        self.geometryType = (enum SFGeometryType)[values objectForKey:GPKGS_FEATURE_TABLE_GEOMETRY_TYPE];
    }
    return self;
}

-(enum GPKGSTableType) getType{
    return GPKGS_TT_FEATURE;
}

-(NSDictionary *) getValues{
    
    NSMutableDictionary * values = [[NSMutableDictionary alloc] init];
    [values setValuesForKeysWithDictionary:[super getValues]];
    
    [values setObject:[NSNumber numberWithInt:(int)self.geometryType] forKey:GPKGS_FEATURE_TABLE_GEOMETRY_TYPE];
    
    return values;
}

@end
