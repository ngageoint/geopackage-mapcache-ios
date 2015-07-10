//
//  GPKGSFeatureOverlayTable.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSFeatureTable.h"

@interface GPKGSFeatureOverlayTable : GPKGSFeatureTable

@property (nonatomic, strong) NSString *featureTable;
@property (nonatomic) int minZoom;
@property (nonatomic) int maxZoom;
@property (nonatomic) double minLat;
@property (nonatomic) double maxLat;
@property (nonatomic) double minLon;
@property (nonatomic) double maxLon;

@end
