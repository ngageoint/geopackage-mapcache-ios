//
//  GPKGSLoadTilesTask.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/24/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPKGProgress.h"
#import "GPKGSLoadTilesProtocol.h"
#import "GPKGSDatabases.h"
#import "GPKGCompressFormats.h"
#import "GPKGBoundingBox.h"
#import "GPKGGeoPackage.h"
#import "GPKGFeatureTiles.h"

@interface GPKGSLoadTilesTask : NSObject<GPKGProgress>

+(void) loadTilesWithCallback: (NSObject<GPKGSLoadTilesProtocol> *) callback
                  andDatabase: (NSString *) database
                         andTable: (NSString *) tableName
                       andUrl: (NSString *) tileUrl
                   andMinZoom: (int) minZoom
                   andMaxZoom: (int) maxZoom
            andCompressFormat: (enum GPKGCompressFormat) compressFormat
           andCompressQuality: (int) compressQuality
             andCompressScale: (int) compressScale
            andStandardFormat: (BOOL) standardWebMercatorFormat
               andBoundingBox: (GPKGBoundingBox *) boundingBox;

+(void) loadTilesWithCallback: (NSObject<GPKGSLoadTilesProtocol> *) callback
                  andGeoPackage: (GPKGGeoPackage *) geoPackage
                     andTable: (NSString *) tableName
                       andFeatureTiles: (GPKGFeatureTiles *) featureTiles
                   andMinZoom: (int) minZoom
                   andMaxZoom: (int) maxZoom
            andCompressFormat: (enum GPKGCompressFormat) compressFormat
           andCompressQuality: (int) compressQuality
             andCompressScale: (int) compressScale
            andStandardFormat: (BOOL) standardWebMercatorFormat
               andBoundingBox: (GPKGBoundingBox *) boundingBox;

@end
