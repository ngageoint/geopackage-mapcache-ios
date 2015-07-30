//
//  GPKGSFeatureTilesDrawData.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/28/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GPKGSFeatureTilesDrawData : NSObject

@property (nonatomic, strong) NSNumber * pointAlpha;
@property (nonatomic, strong) NSDecimalNumber * pointRadius;
@property (nonatomic, strong) NSNumber * lineAlpha;
@property (nonatomic, strong) NSDecimalNumber * lineStroke;
@property (nonatomic, strong) NSNumber * polygonAlpha;
@property (nonatomic, strong) NSDecimalNumber * polygonStroke;
@property (nonatomic) BOOL polygonFill;
@property (nonatomic, strong) NSNumber * polygonFillAlpha;

@end
