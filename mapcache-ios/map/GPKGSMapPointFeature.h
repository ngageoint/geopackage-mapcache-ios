//
//  GPKGSMapPointFeature.h
//  mapcache-ios
//
//  Created by Brian Osborn on 8/13/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GPKGSMapPointFeature : NSObject

@property (nonatomic) int featureId;
@property (nonatomic, strong) NSString * database;
@property (nonatomic, strong) NSString * tableName;

@end
