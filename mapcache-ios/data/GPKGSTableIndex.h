//
//  GPKGSTableIndex.h
//  mapcache-ios
//
//  Created by Brian Osborn on 10/22/15.
//  Copyright © 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPKGSTable.h"
#import "GPKGFeatureIndexTypes.h"

@interface GPKGSTableIndex : NSObject

@property (nonatomic, strong) GPKGSTable *table;
@property (nonatomic) enum GPKGFeatureIndexType indexLocation;

-(instancetype) initWithTable: (GPKGSTable *) table andIndexLocation: (enum GPKGFeatureIndexType) indexLocation;

@end
