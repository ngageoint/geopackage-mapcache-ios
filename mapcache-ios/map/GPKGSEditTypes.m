//
//  GPKGSEditTypes.m
//  mapcache-ios
//
//  Created by Brian Osborn on 8/14/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSEditTypes.h"
#import "GPKGUtils.h"

NSString * const GPKGS_ET_NONE_NAME = @"None";
NSString * const GPKGS_ET_POINT_NAME = @"Point";
NSString * const GPKGS_ET_LINESTRING_NAME = @"Linestring";
NSString * const GPKGS_ET_POLYGON_NAME = @"Polygon";
NSString * const GPKGS_ET_POLYGON_HOLE_NAME = @"Polygon Hole";
NSString * const GPKGS_ET_EDIT_FEATURE_NAME = @"Edit Feature";

@implementation GPKGSEditTypes

+(NSString *) name: (enum GPKGSEditType) editType{
    NSString * name = nil;
    
    switch(editType){
        case GPKGS_ET_NONE:
            name = GPKGS_ET_NONE_NAME;
            break;
        case GPKGS_ET_POINT:
            name = GPKGS_ET_POINT_NAME;
            break;
        case GPKGS_ET_LINESTRING:
            name = GPKGS_ET_LINESTRING_NAME;
            break;
        case GPKGS_ET_POLYGON:
            name = GPKGS_ET_POLYGON_NAME;
            break;
        case GPKGS_ET_POLYGON_HOLE:
            name = GPKGS_ET_POLYGON_HOLE_NAME;
            break;
        case GPKGS_ET_EDIT_FEATURE:
            name = GPKGS_ET_EDIT_FEATURE_NAME;
            break;
    }
    
    return name;
}

+(NSString *) pointName: (enum GPKGSEditType) editType{
    NSString * name = [self name:editType];
    switch(editType){
        case GPKGS_ET_LINESTRING:
        case GPKGS_ET_POLYGON:
        case GPKGS_ET_POLYGON_HOLE:
            name = [NSString stringWithFormat:@"%@ %@", name, GPKGS_ET_POINT_NAME];
            break;
        default:
            break;
    }
    return name;
}

+(enum GPKGSEditType) fromName: (NSString *) name{
    enum GPKGSEditType value = -1;
    
    if(name != nil){
        name = [name uppercaseString];
        NSDictionary *types = [NSDictionary dictionaryWithObjectsAndKeys:
                               [NSNumber numberWithInteger:GPKGS_ET_NONE], GPKGS_ET_NONE_NAME,
                               [NSNumber numberWithInteger:GPKGS_ET_POINT], GPKGS_ET_POINT_NAME,
                               [NSNumber numberWithInteger:GPKGS_ET_LINESTRING], GPKGS_ET_LINESTRING_NAME,
                               [NSNumber numberWithInteger:GPKGS_ET_POLYGON], GPKGS_ET_POLYGON_NAME,
                               [NSNumber numberWithInteger:GPKGS_ET_POLYGON_HOLE], GPKGS_ET_POLYGON_HOLE_NAME,
                               [NSNumber numberWithInteger:GPKGS_ET_EDIT_FEATURE], GPKGS_ET_EDIT_FEATURE_NAME,
                               nil
                               ];
        NSNumber *enumValue = [GPKGUtils objectForKey:name inDictionary:types];
        value = (enum GPKGSEditType)[enumValue intValue];
    }
    
    return value;
}

@end
