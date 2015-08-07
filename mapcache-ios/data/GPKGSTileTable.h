//
//  GPKGSTileTable.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSTable.h"

@interface GPKGSTileTable : GPKGSTable

-(instancetype) initWithDatabase: (NSString *) database andName: (NSString *) name andCount: (int) count;

@end
