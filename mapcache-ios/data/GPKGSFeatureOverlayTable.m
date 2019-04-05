//
//  GPKGSFeatureOverlayTable.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSFeatureOverlayTable.h"
#import "GPKGUtils.h"

NSString * const GPKGS_FEATURE_OVERLAY_TABLE_FEATURE_TABLE = @"feature_table";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_MIN_ZOOM = @"min_zoom";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_MAX_ZOOM = @"max_zoom";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_MAX_FEATURES_PER_TILE = @"max_features_per_tile";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_MIN_LAT = @"min_lat";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_MAX_LAT = @"max_lat";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_MIN_LON = @"min_lon";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_MAX_LON = @"max_lon";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_IGNORE_GEOPACKAGE_STYLES = @"ignore_geopackage_styles";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_POINT_COLOR = @"point_color";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_POINT_COLOR_NAME = @"point_color_name";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_POINT_ALPHA = @"point_alpha";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_POINT_RADIUS = @"point_radius";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_LINE_COLOR = @"line_color";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_LINE_COLOR_NAME = @"line_color_name";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_LINE_ALPHA = @"line_alpha";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_LINE_STROKE = @"line_stroke";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_COLOR = @"polygon_color";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_COLOR_NAME = @"polygon_color_name";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_ALPHA = @"polygon_alpha";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_STROKE = @"polygon_stroke";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_FILL = @"polygon_fill";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_FILL_COLOR = @"polygon_fill_color";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_FILL_COLOR_NAME = @"polygon_fill_color_name";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_FILL_ALPHA = @"polygon_fill_alpha";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_COLOR_SUFFIX_RED = @"_red";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_COLOR_SUFFIX_GREEN = @"_green";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_COLOR_SUFFIX_BLUE = @"_blue";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_COLOR_SUFFIX_WHITE = @"_white";
NSString * const GPKGS_FEATURE_OVERLAY_TABLE_COLOR_SUFFIX_ALPHA = @"_alpha";

@implementation GPKGSFeatureOverlayTable

-(instancetype) initWithDatabase: (NSString *) database andName: (NSString *) name andFeatureTable: (NSString *) featureTable andGeometryType: (enum SFGeometryType) geometryType andCount: (int) count{
    self = [super initWithDatabase:database andName:name andGeometryType:geometryType andCount:count];
    if(self != nil){
        self.featureTable = featureTable;
        self.ignoreGeoPackageStyles = NO;
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
        NSNumber * maxFeaturesPerTile = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_MAX_FEATURES_PER_TILE];
        if(maxFeaturesPerTile != nil && [maxFeaturesPerTile intValue] >= 0){
            self.maxFeaturesPerTile = maxFeaturesPerTile;
        }
        NSDecimalNumber * minLat = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_MIN_LAT];
        self.minLat = [minLat doubleValue];
        NSDecimalNumber * maxLat = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_MAX_LAT];
        self.maxLat = [maxLat doubleValue];
        NSDecimalNumber * minLon = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_MIN_LON];
        self.minLon = [minLon doubleValue];
        NSDecimalNumber * maxLon = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_MAX_LON];
        self.maxLon = [maxLon doubleValue];
        NSNumber * ignoreGeoPackageStyles = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_IGNORE_GEOPACKAGE_STYLES];
        self.ignoreGeoPackageStyles = (BOOL)[ignoreGeoPackageStyles intValue];
        self.pointColor = [self getColorForName:GPKGS_FEATURE_OVERLAY_TABLE_POINT_COLOR inValues:values];
        self.pointColorName = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_POINT_COLOR_NAME];
        NSNumber * pointAlpha = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_POINT_ALPHA];
        self.pointAlpha = [pointAlpha intValue];
        NSDecimalNumber * pointRadius = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_POINT_RADIUS];
        self.pointRadius = [pointRadius doubleValue];
        self.lineColor = [self getColorForName:GPKGS_FEATURE_OVERLAY_TABLE_LINE_COLOR inValues:values];
        self.lineColorName = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_LINE_COLOR_NAME];
        NSNumber * lineAlpha = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_LINE_ALPHA];
        self.lineAlpha = [lineAlpha intValue];
        NSDecimalNumber * lineStroke = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_LINE_STROKE];
        self.lineStroke = [lineStroke doubleValue];
        self.polygonColor = [self getColorForName:GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_COLOR inValues:values];
        self.polygonColorName = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_COLOR_NAME];
        NSNumber * polygonAlpha = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_ALPHA];
        self.polygonAlpha = [polygonAlpha intValue];
        NSDecimalNumber * polygonStroke = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_STROKE];
        self.polygonStroke = [polygonStroke doubleValue];
        NSNumber * polygonFill = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_FILL];
        self.polygonFill = (BOOL)[polygonFill intValue];
        self.polygonFillColor = [self getColorForName:GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_FILL_COLOR inValues:values];
        self.polygonFillColorName = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_FILL_COLOR_NAME];
        NSNumber * polygonFillAlpha = [values objectForKey:GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_FILL_ALPHA];
        self.polygonFillAlpha = [polygonFillAlpha intValue];
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
    [values setObject:self.maxFeaturesPerTile != nil ? self.maxFeaturesPerTile : [NSNumber numberWithInt:-1] forKey:GPKGS_FEATURE_OVERLAY_TABLE_MAX_FEATURES_PER_TILE];
    [values setObject:[NSDecimalNumber numberWithDouble:self.minLat] forKey:GPKGS_FEATURE_OVERLAY_TABLE_MIN_LAT];
    [values setObject:[NSDecimalNumber numberWithDouble:self.maxLat] forKey:GPKGS_FEATURE_OVERLAY_TABLE_MAX_LAT];
    [values setObject:[NSDecimalNumber numberWithDouble:self.minLon] forKey:GPKGS_FEATURE_OVERLAY_TABLE_MIN_LON];
    [values setObject:[NSDecimalNumber numberWithDouble:self.maxLon] forKey:GPKGS_FEATURE_OVERLAY_TABLE_MAX_LON];
    [values setObject:[NSNumber numberWithBool:self.ignoreGeoPackageStyles] forKey:GPKGS_FEATURE_OVERLAY_TABLE_IGNORE_GEOPACKAGE_STYLES];
    [self setColor:self.pointColor forName:GPKGS_FEATURE_OVERLAY_TABLE_POINT_COLOR inValues:values];
    [values setObject:self.pointColorName forKey:GPKGS_FEATURE_OVERLAY_TABLE_POINT_COLOR_NAME];
    [values setObject:[NSNumber numberWithInt:self.pointAlpha] forKey:GPKGS_FEATURE_OVERLAY_TABLE_POINT_ALPHA];
    [values setObject:[NSDecimalNumber numberWithDouble:self.pointRadius] forKey:GPKGS_FEATURE_OVERLAY_TABLE_POINT_RADIUS];
    [self setColor:self.lineColor forName:GPKGS_FEATURE_OVERLAY_TABLE_LINE_COLOR inValues:values];
    [values setObject:self.lineColorName forKey:GPKGS_FEATURE_OVERLAY_TABLE_LINE_COLOR_NAME];
    [values setObject:[NSNumber numberWithInt:self.lineAlpha] forKey:GPKGS_FEATURE_OVERLAY_TABLE_LINE_ALPHA];
    [values setObject:[NSDecimalNumber numberWithDouble:self.lineStroke] forKey:GPKGS_FEATURE_OVERLAY_TABLE_LINE_STROKE];
    [self setColor:self.polygonColor forName:GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_COLOR inValues:values];
    [values setObject:self.polygonColorName forKey:GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_COLOR_NAME];
    [values setObject:[NSNumber numberWithInt:self.polygonAlpha] forKey:GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_ALPHA];
    [values setObject:[NSDecimalNumber numberWithDouble:self.polygonStroke] forKey:GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_STROKE];
    [values setObject:[NSNumber numberWithBool:self.polygonFill] forKey:GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_FILL];
    [self setColor:self.polygonFillColor forName:GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_FILL_COLOR inValues:values];
    [values setObject:self.polygonFillColorName forKey:GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_FILL_COLOR_NAME];
    [values setObject:[NSNumber numberWithInt:self.polygonFillAlpha] forKey:GPKGS_FEATURE_OVERLAY_TABLE_POLYGON_FILL_ALPHA];
    
    return values;
}

-(UIColor *) getColorForName: (NSString *) name inValues: (NSDictionary *) values{
    
    UIColor * color = nil;
    
    NSDecimalNumber * white = [values objectForKey:[NSString stringWithFormat:@"%@%@", name, GPKGS_FEATURE_OVERLAY_TABLE_COLOR_SUFFIX_WHITE]];
    if(white != nil){
        NSDecimalNumber * alpha = [values objectForKey:[NSString stringWithFormat:@"%@%@", name, GPKGS_FEATURE_OVERLAY_TABLE_COLOR_SUFFIX_ALPHA]];
        color = [UIColor colorWithWhite:[white doubleValue] alpha:[alpha doubleValue]];
    }else{
        NSDecimalNumber * red = [values objectForKey:[NSString stringWithFormat:@"%@%@", name, GPKGS_FEATURE_OVERLAY_TABLE_COLOR_SUFFIX_RED]];
        NSDecimalNumber * green = [values objectForKey:[NSString stringWithFormat:@"%@%@", name, GPKGS_FEATURE_OVERLAY_TABLE_COLOR_SUFFIX_GREEN]];
        NSDecimalNumber * blue = [values objectForKey:[NSString stringWithFormat:@"%@%@", name, GPKGS_FEATURE_OVERLAY_TABLE_COLOR_SUFFIX_BLUE]];
        NSDecimalNumber * alpha = [values objectForKey:[NSString stringWithFormat:@"%@%@", name, GPKGS_FEATURE_OVERLAY_TABLE_COLOR_SUFFIX_ALPHA]];
        color = [UIColor colorWithRed:[red doubleValue] green:[green doubleValue] blue:[blue doubleValue] alpha:[alpha doubleValue]];
    }
    
    return color;
}

-(void) setColor: (UIColor *) color forName: (NSString *) name inValues: (NSMutableDictionary *) values{
    
    if(CGColorGetNumberOfComponents(color.CGColor) == 2){
        CGFloat white = 0.0, alpha = 0.0;
        [color getWhite:&white alpha:&alpha];
        [values setObject:[NSDecimalNumber numberWithDouble:white] forKey:[NSString stringWithFormat:@"%@%@", name, GPKGS_FEATURE_OVERLAY_TABLE_COLOR_SUFFIX_WHITE]];
        [values setObject:[NSDecimalNumber numberWithDouble:alpha] forKey:[NSString stringWithFormat:@"%@%@", name, GPKGS_FEATURE_OVERLAY_TABLE_COLOR_SUFFIX_ALPHA]];
    }else{
        CGFloat red = 0.0, green = 0.0, blue = 0.0, alpha = 0.0;
        [color getRed:&red green:&green blue:&blue alpha:&alpha];
        [values setObject:[NSDecimalNumber numberWithDouble:red] forKey:[NSString stringWithFormat:@"%@%@", name, GPKGS_FEATURE_OVERLAY_TABLE_COLOR_SUFFIX_RED]];
        [values setObject:[NSDecimalNumber numberWithDouble:green] forKey:[NSString stringWithFormat:@"%@%@", name, GPKGS_FEATURE_OVERLAY_TABLE_COLOR_SUFFIX_GREEN]];
        [values setObject:[NSDecimalNumber numberWithDouble:blue] forKey:[NSString stringWithFormat:@"%@%@", name, GPKGS_FEATURE_OVERLAY_TABLE_COLOR_SUFFIX_BLUE]];
        [values setObject:[NSDecimalNumber numberWithDouble:alpha] forKey:[NSString stringWithFormat:@"%@%@", name, GPKGS_FEATURE_OVERLAY_TABLE_COLOR_SUFFIX_ALPHA]];
    }
    
}

@end
