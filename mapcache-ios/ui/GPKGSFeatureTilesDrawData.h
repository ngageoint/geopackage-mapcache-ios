//
//  GPKGSFeatureTilesDrawData.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/28/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GPKGSFeatureTilesDrawData : NSObject

@property (nonatomic, strong) UIColor * pointColor;
@property (nonatomic, strong) NSString * pointColorName;
@property (nonatomic, strong) NSNumber * pointAlpha;
@property (nonatomic, strong) NSDecimalNumber * pointRadius;
@property (nonatomic, strong) UIColor * lineColor;
@property (nonatomic, strong) NSString * lineColorName;
@property (nonatomic, strong) NSNumber * lineAlpha;
@property (nonatomic, strong) NSDecimalNumber * lineStroke;
@property (nonatomic, strong) UIColor * polygonColor;
@property (nonatomic, strong) NSString * polygonColorName;
@property (nonatomic, strong) NSNumber * polygonAlpha;
@property (nonatomic, strong) NSDecimalNumber * polygonStroke;
@property (nonatomic) BOOL polygonFill;
@property (nonatomic, strong) UIColor * polygonFillColor;
@property (nonatomic, strong) NSString * polygonFillColorName;
@property (nonatomic, strong) NSNumber * polygonFillAlpha;

-(UIColor *) getPointAlphaColor;

-(UIColor *) getLineAlphaColor;

-(UIColor *) getPolygonAlphaColor;

-(UIColor *) getPolygonFillAlphaColor;

@end
