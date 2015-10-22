//
//  GPKGSIndexerTask.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/15/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPKGProgress.h"
#import "GPKGSIndexerProtocol.h"
#import "GPKGFeatureIndexTypes.h"

@interface GPKGSIndexerTask : NSObject<GPKGProgress>

+(void) indexFeaturesWithCallback: (NSObject<GPKGSIndexerProtocol> *) callback
                      andDatabase: (NSString *) database
                         andTable: (NSString *) tableName
                      andFeatureIndexType: (enum GPKGFeatureIndexType) indexLocation;

@end
