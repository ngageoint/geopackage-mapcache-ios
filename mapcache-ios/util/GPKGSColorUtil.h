//
//  GPKGSColorUtil.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/30/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface GPKGSColorUtil : NSObject
+ (UIColor *) getPrimary;
+ (UIColor *) getPrimaryLight;

+ (UIColor *) getPolygonFillColor;
+ (UIColor *) getPolygonStrokeColor;


+ (UIColor *) getAccent;
+ (UIColor *) getAccentLight;

+ (UIColor *) getMediumGrey;

//+ (UIColor *) getBackgroundColor;
//- (UIColor *) getDanger;
//- (UIColor *) getWarning;
//- (UIColor *) getSuccess;
//- (UIColor *) getInfo;

@end
