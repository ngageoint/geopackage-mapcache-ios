//
//  GPKGSTableTypes.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>

enum GPKGSTableType{
    GPKGS_TT_FEATURE,
    GPKGS_TT_TILE,
    GPKGS_TT_FEATURE_OVERLAY
};

extern NSString * const GPKGS_TT_FEATURE_NAME;
extern NSString * const GPKGS_TT_TILE_NAME;
extern NSString * const GPKGS_TT_FEATURE_OVERLAY_NAME;

@interface MCTableTypes : NSObject

+(NSString *) name: (enum GPKGSTableType) tableType;

+(enum GPKGSTableType) fromName: (NSString *) name;

@end
