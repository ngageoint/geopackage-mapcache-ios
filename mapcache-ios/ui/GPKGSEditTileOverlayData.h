//
//  GPKGSEditTileOverlayData.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/29/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPKGBoundingBox.h"
#import "GPKGSFeatureTilesDrawData.h"

@interface GPKGSEditTileOverlayData : NSObject

@property (nonatomic, strong) NSNumber * minZoom;
@property (nonatomic, strong) NSNumber * maxZoom;
@property (nonatomic, strong) GPKGBoundingBox * boundingBox;
@property (nonatomic, strong) GPKGSFeatureTilesDrawData * featureTilesDraw;
@property (nonatomic) BOOL indexed;

@end
