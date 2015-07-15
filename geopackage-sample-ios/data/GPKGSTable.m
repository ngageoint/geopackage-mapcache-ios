//
//  GPKGTable.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSTable.h"

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

-(enum GPKGSTableType) getType{
    [self doesNotRecognizeSelector:_cmd];
    return GPKGS_TT_FEATURE;
}

@end
