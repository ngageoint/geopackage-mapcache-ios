//
//  GPKGSFeatureOverlayTable.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSFeatureTable.h"
#import <UIKit/UIKit.h>

@interface GPKGSFeatureOverlayTable : GPKGSFeatureTable

@property (nonatomic, strong) NSString *featureTable;
@property (nonatomic) int minZoom;
@property (nonatomic) int maxZoom;
@property (nonatomic, strong) NSNumber * maxFeaturesPerTile;
@property (nonatomic) double minLat;
@property (nonatomic) double maxLat;
@property (nonatomic) double minLon;
@property (nonatomic) double maxLon;
@property (nonatomic, strong) UIColor * pointColor;
@property (nonatomic, strong) NSString * pointColorName;
@property (nonatomic) int pointAlpha;
@property (nonatomic) double pointRadius;
@property (nonatomic, strong) UIColor * lineColor;
@property (nonatomic, strong) NSString * lineColorName;
@property (nonatomic) int lineAlpha;
@property (nonatomic) double lineStroke;
@property (nonatomic, strong) UIColor * polygonColor;
@property (nonatomic, strong) NSString * polygonColorName;
@property (nonatomic) int polygonAlpha;
@property (nonatomic) double polygonStroke;
@property (nonatomic) BOOL polygonFill;
@property (nonatomic, strong) UIColor * polygonFillColor;
@property (nonatomic, strong) NSString * polygonFillColorName;
@property (nonatomic) int polygonFillAlpha;

-(instancetype) initWithDatabase: (NSString *) database andName: (NSString *) name andFeatureTable: (NSString *) featureTable andGeometryType: (enum SFGeometryType) geometryType andCount: (int) count;

-(instancetype) initWithValues: (NSDictionary *) values;

@end
