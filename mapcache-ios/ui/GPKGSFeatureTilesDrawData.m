//
//  GPKGSFeatureTilesDrawData.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/28/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSFeatureTilesDrawData.h"

@implementation GPKGSFeatureTilesDrawData

-(UIColor *) getPointAlphaColor{
    return [self getColor:self.pointColor withAlpha:[self.pointAlpha intValue]];
}

-(UIColor *) getLineAlphaColor{
    return [self getColor:self.lineColor withAlpha:[self.lineAlpha intValue]];
}

-(UIColor *) getPolygonAlphaColor{
    return [self getColor:self.polygonColor withAlpha:[self.polygonAlpha intValue]];
}

-(UIColor *) getPolygonFillAlphaColor{
    return [self getColor:self.polygonFillColor withAlpha:[self.polygonFillAlpha intValue]];
}

-(UIColor *) getColor: (UIColor *) color withAlpha: (int) alpha{
    UIColor * alphaColor = nil;
    if(alpha < 255){
        CGColorRef cgColor = CGColorCreateCopyWithAlpha(color.CGColor, alpha/255.0);
        alphaColor = [UIColor colorWithCGColor:cgColor];
        CGColorRelease(cgColor);
    }else{
        alphaColor = color;
    }
    return alphaColor;
}

@end
