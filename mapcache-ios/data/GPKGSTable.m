//
//  GPKGTable.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSTable.h"

NSString * const GPKGS_TABLE_DATABASE = @"database";
NSString * const GPKGS_TABLE_NAME = @"name";
NSString * const GPKGS_TABLE_COUNT = @"count";
NSString * const GPKGS_TABLE_ACTIVE = @"active";

@implementation GPKGSTable

-(instancetype) initWithDatabase: (NSString *) database andName: (NSString *) name andCount: (int) count{
    self = [super init];
    if(self != nil){
        self.database = database;
        self.name = name;
        self.count = count;
    }
    return self;
}

-(instancetype) initWithValues: (NSDictionary *) values{
    NSString * database = [values objectForKey:GPKGS_TABLE_DATABASE];
    NSString * name = [values objectForKey:GPKGS_TABLE_NAME];
    NSNumber * count = [values objectForKey:GPKGS_TABLE_COUNT];
    NSNumber * active = [values objectForKey:GPKGS_TABLE_ACTIVE];
    self = [self initWithDatabase:database andName:name andCount:[count intValue]];
    if(self != nil){
        self.active = [active boolValue];
    }
    return self;
}

-(enum GPKGSTableType) getType{
    [self doesNotRecognizeSelector:_cmd];
    return GPKGS_TT_FEATURE;
}

-(NSDictionary *) getValues{
    
    NSMutableDictionary * values = [[NSMutableDictionary alloc] init];
    
    [values setObject:self.database forKey:GPKGS_TABLE_DATABASE];
    [values setObject:self.name forKey:GPKGS_TABLE_NAME];
    [values setObject:[NSNumber numberWithInt:self.count] forKey:GPKGS_TABLE_COUNT];
    [values setObject:[NSNumber numberWithBool:self.active] forKey:GPKGS_TABLE_ACTIVE];
    
    return values;
}

@end
