//
//  GPKGSFeatureOverlayTable.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSFeatureOverlayTable.h"

NSString * const GPKGS_FEATURE_OVERLAY_TABLE_FEATURE_TABLE = @"feature_table";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_MIN_ZOOM = @"min_zoom";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_MAX_ZOOM = @"max_zoom";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_MIN_LAT = @"min_lat";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_MAX_LAT = @"max_lat";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_MIN_LON = @"min_lon";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_MAX_LON = @"max_lon";

@implementation GPKGSFeatureOverlayTable

-(instancetype) initWithDatabase: (NSString *) database andName: (NSString *) name andFeatureTable: (NSString *) featureTable andGeometryType: (enum WKBGeometryType) geometryType andCount: (int) count{
    self = [super initWithDatabase:database andName:name andGeometryType:geometryType andCount:count];
    if(self != nil){
        self.featureTable = featureTable;
    }
    return self;
}

-(instancetype) initWithValues: (NSDictionary *) values{
    
    self = [super initWithValues:values];
    if(self != nil){
        self.featureTable = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_FEATURE_TABLE];
        NSNumber * minZoom = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_MIN_ZOOM];
        self.minZoom = [minZoom intValue];
        NSNumber * maxZoom = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_MAX_ZOOM];
        self.maxZoom = [maxZoom intValue];
        NSDecimalNumber * minLat = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_MIN_LAT];
        self.minLat = [minLat doubleValue];
        NSDecimalNumber * maxLat = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_MAX_LAT];
        self.maxLat = [maxLat doubleValue];
        NSDecimalNumber * minLon = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_MIN_LON];
        self.minLon = [minLon doubleValue];
        NSDecimalNumber * maxLon = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_MAX_LON];
        self.maxLon = [maxLon doubleValue];
    }
    return self;
}

-(enum GPKGSTableType) getType{
    return GPKGS_TT_FEATURE_OVERLAY;
}

-(NSDictionary *) getValues{
    
    NSMutableDictionary * values = [[NSMutableDictionary alloc] init];
    [values setValuesForKeysWithDictionary:[super getValues]];
    
    [values setObject:self.featureTable forKey:GPKGS_FEATURE_OVERLAY_TABLE_FEATURE_TABLE];
    [values setObject:[NSNumber numberWithInt:self.minZoom] forKey:GPKGS_FEATURE_OVERLAY_TABLE_MIN_ZOOM];
    [values setObject:[NSNumber numberWithInt:self.maxZoom] forKey:GPKGS_FEATURE_OVERLAY_TABLE_MAX_ZOOM];
    [values setObject:[NSDecimalNumber numberWithDouble:self.minLat] forKey:GPKGS_FEATURE_OVERLAY_TABLE_MIN_LAT];
    [values setObject:[NSDecimalNumber numberWithDouble:self.maxLat] forKey:GPKGS_FEATURE_OVERLAY_TABLE_MAX_LAT];
    [values setObject:[NSDecimalNumber numberWithDouble:self.minLon] forKey:GPKGS_FEATURE_OVERLAY_TABLE_MIN_LON];
    [values setObject:[NSDecimalNumber numberWithDouble:self.maxLon] forKey:GPKGS_FEATURE_OVERLAY_TABLE_MAX_LON];
    
    return values;
}

@end
