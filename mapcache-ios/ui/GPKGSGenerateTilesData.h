//
//  GPKGSGenerateTilesData.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/23/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPKGBoundingBox.h"
#import "GPKGCompressFormats.h"

@interface GPKGSGenerateTilesData : NSObject

@property (nonatomic, strong) NSNumber * minZoom;
@property (nonatomic, strong) NSNumber * maxZoom;
@property (nonatomic) BOOL setZooms;
@property (nonatomic, strong) NSNumber * maxFeaturesPerTile;
@property (nonatomic) BOOL supportsMaxFeatures;
@property (nonatomic) enum GPKGCompressFormat compressFormat;
@property (nonatomic, strong) NSNumber * compressQuality;
@property (nonatomic, strong) NSNumber * compressScale;
@property (nonatomic) BOOL xyzTiles;
@property (nonatomic, strong) GPKGBoundingBox * boundingBox;

-(instancetype) init;

@end
