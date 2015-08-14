//
//  GPKGSEditTypes.h
//  mapcache-ios
//
//  Created by Brian Osborn on 8/14/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>

enum GPKGSEditType{
    GPKGS_ET_NONE,
    GPKGS_ET_POINT,
    GPKGS_ET_LINESTRING,
    GPKGS_ET_POLYGON,
    GPKGS_ET_POLYGON_HOLE,
    GPKGS_ET_EDIT_FEATURE
};

extern NSString * const GPKGS_ET_NONE_NAME;
extern NSString * const GPKGS_ET_POINT_NAME;
extern NSString * const GPKGS_ET_LINESTRING_NAME;
extern NSString * const GPKGS_ET_POLYGON_NAME;
extern NSString * const GPKGS_ET_POLYGON_HOLE_NAME;
extern NSString * const GPKGS_ET_EDIT_FEATURE_NAME;

@interface GPKGSEditTypes : NSObject

+(NSString *) name: (enum GPKGSEditType) editType;

+(NSString *) pointName: (enum GPKGSEditType) editType;

+(enum GPKGSEditType) fromName: (NSString *) name;

@end
