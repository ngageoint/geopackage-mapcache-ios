//
//  GPKGSColorUtil.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/30/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCColorUtil.h"

@implementation MCColorUtil

- (instancetype) init {
    self = [super init];
    
    return self;
}

+ (UIColor *) getPrimary {
    return [UIColor colorWithRed:0.0f green:0.31f blue:0.49f alpha:1];
}


+ (UIColor *) getPrimaryLight {
    return [UIColor colorWithRed:0.15f green:0.47f blue:0.61f alpha:1];
}


+ (UIColor *) getAccent {
    return [UIColor colorWithRed:36.0/255.0 green:169.0/255.0 blue:176.0/255.0 alpha:1.0];
}


+ (UIColor *) getAccentLight {
    return [UIColor colorWithRed:0.51f green:0.78f blue:0.8f alpha:0.85];
}


+ (UIColor *) getMediumGrey {
    return [UIColor colorWithRed:(215/255.0) green:(215/255.0) blue:(215/255.0) alpha:1];
}


+ (UIColor *) getLightGrey {
    return [UIColor colorWithRed:(240/255.0) green:(240/255.0) blue:(240/255.0) alpha:1];
}


+ (UIColor *) getPolygonFillColor {
    return [UIColor colorWithRed:0.0f green:0.31f blue:0.49f alpha:0.5f];
}


+ (UIColor *) getPolygonStrokeColor {
    return [UIColor colorWithRed:0.0f green:0.31f blue:0.49f alpha:0.8f];
}

@end
