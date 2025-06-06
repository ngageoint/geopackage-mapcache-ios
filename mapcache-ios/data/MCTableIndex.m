//
//  GPKGSTableIndex.m
//  mapcache-ios
//
//  Created by Brian Osborn on 10/22/15.
//  Copyright © 2015 NGA. All rights reserved.
//

#import "MCTableIndex.h"

@implementation MCTableIndex

-(instancetype) initWithTable: (MCTable *) table andIndexLocation: (enum GPKGFeatureIndexType) indexLocation{
    self = [super init];
    if(self != nil){
        self.table = table;
        self.indexLocation = indexLocation;
    }
    return self;
}

@end
