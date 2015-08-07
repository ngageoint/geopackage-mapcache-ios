//
//  GPKGSEditContentsData.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/27/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GPKGSEditContentsData : NSObject

@property (nonatomic, strong) NSString * identifier;
@property (nonatomic, strong) NSString * theDescription;
@property (nonatomic, strong) NSDecimalNumber * minY;
@property (nonatomic, strong) NSDecimalNumber * maxY;
@property (nonatomic, strong) NSDecimalNumber * minX;
@property (nonatomic, strong) NSDecimalNumber * maxX;

@end
