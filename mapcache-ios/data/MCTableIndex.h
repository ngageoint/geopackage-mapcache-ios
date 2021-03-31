//
//  GPKGSTableIndex.h
//  mapcache-ios
//
//  Created by Brian Osborn on 10/22/15.
//  Copyright © 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCTable.h"
#import "GPKGFeatureIndexTypes.h"

@interface MCTableIndex : NSObject

@property (nonatomic, strong) MCTable *table;
@property (nonatomic) enum GPKGFeatureIndexType indexLocation;

-(instancetype) initWithTable: (MCTable *) table andIndexLocation: (enum GPKGFeatureIndexType) indexLocation;

@end
