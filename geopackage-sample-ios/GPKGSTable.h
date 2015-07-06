//
//  GPKGTable.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPKGSTableTypes.h"

@interface GPKGSTable : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *database;
@property (nonatomic) int count;
@property (nonatomic) BOOL active;

-(enum GPKGSTableType) getType;

@end
