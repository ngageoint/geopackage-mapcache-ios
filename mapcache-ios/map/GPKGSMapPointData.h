//
//  GPKGSMapPointData.h
//  mapcache-ios
//
//  Created by Brian Osborn on 8/14/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>

enum GPKGSMapPointDataType{
    GPKGS_MPDT_NONE,
    GPKGS_MPDT_POINT,
    GPKGS_MPDT_EDIT_FEATURE_POINT,
    GPKGS_MPDT_EDIT_FEATURE,
    GPKGS_MPDT_NEW_EDIT_POINT,
    GPKGS_MPDT_NEW_EDIT_HOLE_POINT
};

@interface GPKGSMapPointData : NSObject

@property (nonatomic) enum GPKGSMapPointDataType type;
@property (nonatomic) int featureId;
@property (nonatomic, strong) NSString * database;
@property (nonatomic, strong) NSString * tableName;

@end
