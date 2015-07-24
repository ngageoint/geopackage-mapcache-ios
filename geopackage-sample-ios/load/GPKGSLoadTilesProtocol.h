//
//  GPKGSLoadTilesProtocol.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/24/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#ifndef geopackage_sample_ios_GPKGSLoadTilesProtocol_h
#define geopackage_sample_ios_GPKGSLoadTilesProtocol_h

@protocol GPKGSLoadTilesProtocol <NSObject>

-(void) onLoadTilesCanceled: (NSString *) result withCount: (int) count;

-(void) onLoadTilesFailure: (NSString *) result;

-(void) onLoadTilesCompleted: (int) count;

@end

#endif
