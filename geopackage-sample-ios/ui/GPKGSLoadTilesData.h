//
//  GPKGSLoadTilesData.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/23/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPKGSGenerateTilesData.h"

@interface GPKGSLoadTilesData : NSObject

@property (nonatomic, strong) NSString * url;
@property (nonatomic, strong) GPKGSGenerateTilesData * generateTiles;

-(instancetype) init;

@end
