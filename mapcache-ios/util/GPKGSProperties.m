//
//  GPKGSProperties.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/7/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGIOUtils.h"

static NSDictionary * properties;

@implementation GPKGSProperties

+(NSString *) getValueOfProperty: (NSString *) property{
    
    [self loadProperties];
    
    NSString * value = [properties valueForKey:property];
    
    if(value == nil){
        [NSException raise:@"Required Property" format:@"Required property not found: %@", property];
    }
    
    return value;
}

+(NSNumber *) getNumberValueOfProperty: (NSString *) property{
    
    [self loadProperties];
    
    NSNumber * value = [properties valueForKey:property];
    
    if(value == nil){
        [NSException raise:@"Required Property" format:@"Required property not found: %@", property];
    }
    
    return value;
}

+(NSArray *) getArrayOfProperty: (NSString *) property{
    
    [self loadProperties];
    
    NSArray * value = [properties valueForKey:property];
    
    if(value == nil){
        [NSException raise:@"Required Array Property" format:@"Required array property not found: %@", property];
    }
    
    return value;
}

+(NSDictionary *) getDictionaryOfProperty: (NSString *) property{
    
    [self loadProperties];
    
    NSDictionary * value = [properties valueForKey:property];
    
    if(value == nil){
        [NSException raise:@"Required Dictionary Property" format:@"Required dictionary property not found: %@", property];
    }
    
    return value;
}

+(BOOL) getBoolOfProperty: (NSString *) property{
    
    [self loadProperties];
    
    NSNumber * value = [properties valueForKey:property];
    
    if(value == nil){
        [NSException raise:@"Required Property" format:@"Required property not found: %@", property];
    }
    
    return value.boolValue;
}

+(void) loadProperties{
    if(properties == nil){
        NSString * propertiesPath = [GPKGIOUtils propertyListPathWithName:GPKGS_MAPCACHE_RESOURCES_PROPERTIES];
        properties = [NSDictionary dictionaryWithContentsOfFile:propertiesPath];
    }
}

@end
