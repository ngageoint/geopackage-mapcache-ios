//
//  GPKGSDatabase.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GPKGSDatabase : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic) BOOL expanded;
@property (nonatomic, strong) NSMutableArray *features;
@property (nonatomic, strong) NSMutableArray *tiles;
@property (nonatomic, strong) NSMutableArray *featureOverlays;

@end
