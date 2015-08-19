//
//  GPKGSMapPointDataTypes.h
//  mapcache-ios
//
//  Created by Brian Osborn on 8/19/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GPKGSMapPointDataTypes : NSObject

enum GPKGSMapPointDataType{
    GPKGS_MPDT_NONE,
    GPKGS_MPDT_POINT,
    GPKGS_MPDT_EDIT_FEATURE_POINT,
    GPKGS_MPDT_EDIT_FEATURE,
    GPKGS_MPDT_NEW_EDIT_POINT,
    GPKGS_MPDT_NEW_EDIT_HOLE_POINT
};

@end
