//
//  GPKGSMapPointData.h
//  mapcache-ios
//
//  Created by Brian Osborn on 8/14/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPKGSMapPointDataTypes.h"

@interface GPKGSMapPointData : NSObject

@property (nonatomic) enum GPKGSMapPointDataType type;
@property (nonatomic) int featureId;
@property (nonatomic, strong) NSString * database;
@property (nonatomic, strong) NSString * tableName;

@end
