//
//  GPKGSProperties.m
//  geopackage-sample-ios
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
    
    if(properties == nil){
        NSString * propertiesPath = [GPKGIOUtils getPropertyListPathWithName:GPKGS_SAMPLE_RESOURCES_PROPERTIES];
        properties = [NSDictionary dictionaryWithContentsOfFile:propertiesPath];
    }
    
    NSString * value = [properties valueForKey:property];
    
    if(value == nil){
        [NSException raise:@"Required Property" format:@"Required property not found: %@", property];
    }
    
    return value;
}

@end
