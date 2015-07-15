//
//  GPKGSFeatureTable.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSTable.h"
#import "WKBGeometryTypes.h"

@interface GPKGSFeatureTable : GPKGSTable

@property (nonatomic) enum WKBGeometryType geometryType;

-(instancetype) initWithDatabase: (NSString *) database andName: (NSString *) name andGeometryType: (enum WKBGeometryType) geometryType andCount: (int) count;

@end
