//
//  GPKGTable.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPKGSTableTypes.h"

extern NSString * const GPKGS_TABLE_DATABASE;
extern NSString * const GPKGS_TABLE_NAME;
extern NSString * const GPKGS_TABLE_COUNT;
extern NSString * const GPKGS_TABLE_ACTIVE;

@interface GPKGSTable : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *database;
@property (nonatomic) int count;
@property (nonatomic) BOOL active;

-(instancetype) initWithDatabase: (NSString *) database andName: (NSString *) name andCount: (int) count;

-(instancetype) initWithValues: (NSDictionary *) values;

-(enum GPKGSTableType) getType;

-(NSDictionary *) getValues;

@end
