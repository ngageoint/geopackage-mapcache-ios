//
//  GPKGSCreateTilesData.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/23/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPKGSLoadTilesData.h"

@interface GPKGSCreateTilesData : NSObject

@property (nonatomic, strong) NSString * name;
@property (nonatomic, strong) GPKGSLoadTilesData * loadTiles;

-(instancetype) init;

@end
