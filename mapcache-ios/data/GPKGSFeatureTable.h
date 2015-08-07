//
//  GPKGSFeatureTable.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSTable.h"
#import "WKBGeometryTypes.h"

extern NSString * const GPKGS_FEATURE_TABLE_GEOMETRY_TYPE;

@interface GPKGSFeatureTable : GPKGSTable

@property (nonatomic) enum WKBGeometryType geometryType;

-(instancetype) initWithDatabase: (NSString *) database andName: (NSString *) name andGeometryType: (enum WKBGeometryType) geometryType andCount: (int) count;

-(instancetype) initWithValues: (NSDictionary *) values;

@end
