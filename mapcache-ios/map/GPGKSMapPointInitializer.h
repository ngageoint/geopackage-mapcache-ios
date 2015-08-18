//
//  GPGKSMapPointInitializer.h
//  mapcache-ios
//
//  Created by Brian Osborn on 8/18/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPKGMapPointInitializer.h"
#import "GPKGSMapPointData.h"

@interface GPGKSMapPointInitializer : NSObject <GPKGMapPointInitializer>

@property (nonatomic) enum GPKGSMapPointDataType pointType;

-(instancetype) initWithPointType: (enum GPKGSMapPointDataType) pointType;

@end
