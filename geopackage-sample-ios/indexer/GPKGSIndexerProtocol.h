//
//  GPKGSIndexerProtocol.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/15/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#ifndef geopackage_sample_ios_GPKGSIndexerProtocol_h
#define geopackage_sample_ios_GPKGSIndexerProtocol_h

@protocol GPKGSIndexerProtocol <NSObject>

-(void) onIndexerCanceled: (NSString *) result;

-(void) onIndexerFailure: (NSString *) result;

-(void) onIndexerCompleted: (int) count;

@end

#endif
