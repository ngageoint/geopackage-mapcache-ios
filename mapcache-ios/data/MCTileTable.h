//
//  GPKGSTileTable.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "MCTable.h"

@interface MCTileTable : MCTable

-(instancetype) initWithDatabase: (NSString *) database andName: (NSString *) name andCount: (int) count;
-(instancetype) initWithDatabase: (NSString *) database andName: (NSString *) name andCount: (int) count andMinZoom: (int) minZoom andMaxZoom: (int) maxZoom;
@property (nonatomic) int minZoom;
@property (nonatomic) int maxZoom;

@end
