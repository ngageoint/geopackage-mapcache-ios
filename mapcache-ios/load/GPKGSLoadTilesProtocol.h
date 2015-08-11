//
//  GPKGSLoadTilesProtocol.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/24/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#ifndef mapcache_ios_GPKGSLoadTilesProtocol_h
#define mapcache_ios_GPKGSLoadTilesProtocol_h

@protocol GPKGSLoadTilesProtocol <NSObject>

-(void) onLoadTilesCanceled: (NSString *) result withCount: (int) count;

-(void) onLoadTilesFailure: (NSString *) result withCount: (int) count;

-(void) onLoadTilesCompleted: (int) count;

@end

#endif
