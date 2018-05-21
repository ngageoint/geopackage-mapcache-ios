//
//  GPKGSFeatureTable.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSTable.h"
#import "SFGeometryTypes.h"

extern NSString * const GPKGS_FEATURE_TABLE_GEOMETRY_TYPE;

@interface GPKGSFeatureTable : GPKGSTable

@property (nonatomic) enum SFGeometryType geometryType;

-(instancetype) initWithDatabase: (NSString *) database andName: (NSString *) name andGeometryType: (enum SFGeometryType) geometryType andCount: (int) count;

-(instancetype) initWithValues: (NSDictionary *) values;

@end
