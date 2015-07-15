//
//  GPKGSFeatureOverlayTable.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSFeatureTable.h"

extern NSString * const GPKGS_FEATURE_OVERLAY_TABLE_FEATURE_TABLE;
extern NSString * const GPKGS_FEATURE_OVERLAY_TABLE_MIN_ZOOM;
extern NSString * const GPKGS_FEATURE_OVERLAY_TABLE_MAX_ZOOM;
extern NSString * const GPKGS_FEATURE_OVERLAY_TABLE_MIN_LAT;
extern NSString * const GPKGS_FEATURE_OVERLAY_TABLE_MAX_LAT;
extern NSString * const GPKGS_FEATURE_OVERLAY_TABLE_MIN_LON;
extern NSString * const GPKGS_FEATURE_OVERLAY_TABLE_MAX_LON;

@interface GPKGSFeatureOverlayTable : GPKGSFeatureTable

@property (nonatomic, strong) NSString *featureTable;
@property (nonatomic) int minZoom;
@property (nonatomic) int maxZoom;
@property (nonatomic) double minLat;
@property (nonatomic) double maxLat;
@property (nonatomic) double minLon;
@property (nonatomic) double maxLon;

-(instancetype) initWithDatabase: (NSString *) database andName: (NSString *) name andFeatureTable: (NSString *) featureTable andGeometryType: (enum WKBGeometryType) geometryType andCount: (int) count;

-(instancetype) initWithValues: (NSDictionary *) values;

@end
