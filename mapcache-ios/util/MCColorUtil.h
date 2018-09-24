//
//  GPKGSColorUtil.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/30/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface MCColorUtil : NSObject
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

@property (nonatomic, strong) UIColor *primaryColor;
@property (nonatomic, strong) UIColor *primaryLightColor;
@property (nonatomic, strong) UIColor *accentColor;
@property (nonatomic, strong) UIColor *accentLightColor;
@property (nonatomic, strong) UIColor *mediumGreyColorColor;
@property (nonatomic, strong) UIColor *polygonFillColor;
@property (nonatomic, strong) UIColor *polygonStrokeColor;
@property (nonatomic, strong) UIColor *boundingBoxColor;
@property (nonatomic, strong) UIColor *polylineColor;
@end
