//
//  GPKGSTableTypes.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSTableTypes.h"
#import "GPKGUtils.h"

NSString * const GPKGS_TT_FEATURE_NAME = @"FEATURE";
NSString * const GPKGS_TT_TILE_NAME = @"TILE";
NSString * const GPKGS_TT_FEATURE_OVERLAY_NAME = @"FEATURE_OVERLAY";

@implementation GPKGSTableTypes

+(NSString *) name: (enum GPKGSTableType) tableType{
    NSString * name = nil;
    
    switch(tableType){
        case GPKGS_TT_FEATURE:
            name = GPKGS_TT_FEATURE_NAME;
            break;
        case GPKGS_TT_TILE:
            name = GPKGS_TT_TILE_NAME;
            break;
        case GPKGS_TT_FEATURE_OVERLAY:
            name = GPKGS_TT_FEATURE_OVERLAY_NAME;
            break;
    }
    
    return name;
}

+(enum GPKGSTableType) fromName: (NSString *) name{
    enum GPKGSTableType value = -1;
    
    if(name != nil){
        NSDictionary *types = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithInteger:GPKGS_TT_FEATURE], GPKGS_TT_FEATURE_NAME,
                               [NSNumber numberWithInteger:GPKGS_TT_TILE], GPKGS_TT_TILE_NAME,
                               [NSNumber numberWithInteger:GPKGS_TT_FEATURE_OVERLAY], GPKGS_TT_FEATURE_OVERLAY_NAME,
                               nil
                               ];
        NSNumber *enumValue = [GPKGUtils objectForKey:name inDictionary:types];
        value = (enum GPKGSTableType)[enumValue intValue];
    }
    
    return value;
}

@end
