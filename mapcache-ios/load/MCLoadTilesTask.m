//
//  GPKGSLoadTilesTask.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/24/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "MCLoadTilesTask.h"
#import "GPKGTileGenerator.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGUrlTileGenerator.h"
#import "GPKGFeatureTileGenerator.h"
#import "MCUtils.h"
#import "MCProperties.h"
#import "MCConstants.h"
#import "PROJProjectionFactory.h"
#import "SFPGeometryTransform.h"
#import "PROJProjectionConstants.h"
#import "GPKGTileBoundingBoxUtils.h"
#import "SlowServerNotifier.h"

@interface MCLoadTilesTask ()

@property (nonatomic, strong) NSNumber *maxTiles;
@property (nonatomic) int progress;
@property (nonatomic, strong) GPKGTileGenerator *tileGenerator;
@property (nonatomic, strong) NSObject<GPKGSLoadTilesProtocol> *callback;
@property (nonatomic) BOOL canceled;
@property (nonatomic, strong) NSString *error;
@property (nonatomic, strong) UIAlertView *alertView;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic) double lastProgressTime;
@property (nonatomic, strong) SlowServerNotifier *slowNotifier;
@property (nonatomic, strong) NSString *host;

@end

@implementation MCLoadTilesTask

// Update to use the new auth method
+(void) loadTilesWithCallback: (NSObject<GPKGSLoadTilesProtocol> *) callback
                  andDatabase: (NSString *) database
                     andTable: (NSString *) tableName
                       andUrl: (NSString *) tileUrl
                   andMinZoom: (int) minZoom
                   andMaxZoom: (int) maxZoom
            andCompressFormat: (enum GPKGCompressFormat) compressFormat
           andCompressQuality: (int) compressQuality
             andCompressScale: (int) compressScale
                  andXyzTiles: (BOOL) xyzTiles
               andBoundingBox: (GPKGBoundingBox *) boundingBox
               andTileScaling: (GPKGTileScaling *) scaling
                 andAuthority: (NSString *) authority
                      andCode: (NSString *) code
                     andLabel: (NSString *) label{
    
    GPKGGeoPackageManager *manager = [GPKGGeoPackageFactory manager];
    GPKGGeoPackage * geoPackage = nil;
    @try {
        geoPackage = [manager open:database];
        
        PROJProjection * projection = [PROJProjectionFactory projectionWithAuthority:authority andCode:code];
        GPKGBoundingBox * bbox = [self transformBoundingBox:boundingBox withProjection:projection];
        
        GPKGTileGenerator * tileGenerator = [[GPKGUrlTileGenerator alloc] initWithGeoPackage:geoPackage andTableName:tableName andTileUrl:tileUrl andMinZoom:minZoom andMaxZoom:maxZoom andBoundingBox:bbox andProjection:projection];
        [self setTileGenerator:tileGenerator withMinZoom:minZoom andMaxZoom:maxZoom andCompressFormat:compressFormat andCompressQuality:compressQuality andCompressScale:compressScale andXyzTiles:xyzTiles andBoundingBox:boundingBox andTileScaling:scaling];
        
        [self loadTilesWithCallback:callback andGeoPackage:geoPackage andTable:tableName andTileGenerator:tileGenerator andLabel:label andUrl: tileUrl];

    } @catch(NSException *e) {
        NSLog(@"---------- MCLoadTilesTask - Problem downloading tiles\n%@", e.reason);
    }
    @finally {
        [manager close];
    }
}

+(void) loadTilesWithCallback: (NSObject<GPKGSLoadTilesProtocol> *) callback
                  andDatabase: (NSString *) database
                     andTable: (NSString *) tableName
                       andUrl: (NSString *) tileUrl
                  andUsername: (NSString *) username
                  andPassword: (NSString *) password
                   andMinZoom: (int) minZoom
                   andMaxZoom: (int) maxZoom
            andCompressFormat: (enum GPKGCompressFormat) compressFormat
           andCompressQuality: (int) compressQuality
             andCompressScale: (int) compressScale
                  andXyzTiles: (BOOL) xyzTiles
               andBoundingBox: (GPKGBoundingBox *) boundingBox
               andTileScaling: (GPKGTileScaling *) scaling
                 andAuthority: (NSString *) authority
                      andCode: (NSString *) code
                     andLabel: (NSString *) label{
    
    GPKGGeoPackageManager *manager = [GPKGGeoPackageFactory manager];
    GPKGGeoPackage * geoPackage = nil;
    @try {
        geoPackage = [manager open:database];
        
        PROJProjection * projection = [PROJProjectionFactory projectionWithAuthority:authority andCode:code];
        GPKGBoundingBox * bbox = [self transformBoundingBox:boundingBox withProjection:projection];
        GPKGUrlTileGenerator *urlTileGenerator = [[GPKGUrlTileGenerator alloc] initWithGeoPackage:geoPackage
                                                                                     andTableName:tableName
                                                                                       andTileUrl:tileUrl
                                                                                       andMinZoom:minZoom
                                                                                       andMaxZoom:maxZoom andBoundingBox:bbox
                                                                                    andProjection:projection];
        
        if (username && password && ![username isEqualToString:@""] && ![password isEqualToString:@""]) {
            NSString *userPasswordString = [NSString stringWithFormat: @"%@:%@", username, password];
            NSData *userPasswordData = [userPasswordString dataUsingEncoding:NSUTF8StringEncoding];
            NSString *base64EncodedCredential = [userPasswordData base64EncodedStringWithOptions:0];
            NSString * authString = [NSString stringWithFormat:@"Basic %@", base64EncodedCredential];
            [urlTileGenerator addValue:authString forHTTPHeaderField:@"Authorization"];
        }
        
        [self setTileGenerator:urlTileGenerator withMinZoom:minZoom andMaxZoom:maxZoom andCompressFormat:compressFormat andCompressQuality:compressQuality andCompressScale:compressScale andXyzTiles:xyzTiles andBoundingBox:boundingBox andTileScaling:scaling];
        
        [self loadTilesWithCallback:callback andGeoPackage:geoPackage andTable:tableName andTileGenerator:urlTileGenerator andLabel:label andUrl:tileUrl];

    } @catch(NSException *e) {
        NSLog(@"---------- MCLoadTilesTask - Problem downloading tiles\n%@", e.reason);
    }
    @finally {
        [manager close];
    }
}

+(void) loadTilesWithCallback: (NSObject<GPKGSLoadTilesProtocol> *) callback
                andGeoPackage: (GPKGGeoPackage *) geoPackage
                     andTable: (NSString *) tableName
              andFeatureTiles: (GPKGFeatureTiles *) featureTiles
                   andMinZoom: (int) minZoom
                   andMaxZoom: (int) maxZoom
            andCompressFormat: (enum GPKGCompressFormat) compressFormat
           andCompressQuality: (int) compressQuality
             andCompressScale: (int) compressScale
                  andXyzTiles: (BOOL) xyzTiles
               andBoundingBox: (GPKGBoundingBox *) boundingBox
               andTileScaling: (GPKGTileScaling *) scaling
                 andAuthority: (NSString *) authority
                      andCode: (NSString *) code
                     andLabel: (NSString *) label
                       andUrl: (NSString *) tileUrl{
    
    PROJProjection * projection = [PROJProjectionFactory projectionWithAuthority:authority andCode:code];
    GPKGBoundingBox * bbox = [self transformBoundingBox:boundingBox withProjection:projection];
    
    GPKGTileGenerator * tileGenerator = [[GPKGFeatureTileGenerator alloc] initWithGeoPackage:geoPackage andTableName:tableName andFeatureTiles:featureTiles andMinZoom:minZoom andMaxZoom:maxZoom andBoundingBox:bbox andProjection:projection];
    [self setTileGenerator:tileGenerator withMinZoom:minZoom andMaxZoom:maxZoom andCompressFormat:compressFormat andCompressQuality:compressQuality andCompressScale:compressScale andXyzTiles:xyzTiles andBoundingBox:boundingBox andTileScaling:scaling];
    
    [self loadTilesWithCallback:callback andGeoPackage:geoPackage andTable:tableName andTileGenerator:tileGenerator andLabel:label andUrl:tileUrl];
}

+(GPKGBoundingBox *) transformBoundingBox: (GPKGBoundingBox *) boundingBox withProjection: (PROJProjection *) projection{
    
    GPKGBoundingBox * transformedBox = boundingBox;
    
    if(![projection isEqualToAuthority:PROJ_AUTHORITY_EPSG andNumberCode:[NSNumber numberWithInt:PROJ_EPSG_WORLD_GEODETIC_SYSTEM]]){
        GPKGBoundingBox * bounded = [GPKGTileBoundingBoxUtils boundWgs84BoundingBoxWithWebMercatorLimits:boundingBox];
        SFPGeometryTransform * transform = [SFPGeometryTransform transformFromEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM andToProjection:projection];
        transformedBox = [bounded transform:transform];
    }
    
    return transformedBox;
}

+(void) setTileGenerator: (GPKGTileGenerator *) tileGenerator
             withMinZoom: (int) minZoom
              andMaxZoom: (int) maxZoom
       andCompressFormat: (enum GPKGCompressFormat) compressFormat
      andCompressQuality: (int) compressQuality
        andCompressScale: (int) compressScale
             andXyzTiles: (BOOL) xyzTiles
          andBoundingBox: (GPKGBoundingBox *) boundingBox
          andTileScaling: (GPKGTileScaling *) scaling{
    
    if(minZoom > maxZoom){
        [NSException raise:@"Zoom Range" format:@"Min zoom of %d can not be larger than max zoom of %d", minZoom, maxZoom];
    }
    
    [tileGenerator setCompressFormat:compressFormat];
    [tileGenerator setCompressQualityAsIntPercentage:compressQuality];
    [tileGenerator setCompressScaleAsIntPercentage:compressScale];
    [tileGenerator setXyzTiles:xyzTiles];
    [tileGenerator setScaling:scaling];
}

+(void) loadTilesWithCallback:(NSObject<GPKGSLoadTilesProtocol> *)callback andGeoPackage:(GPKGGeoPackage *)geoPackage andTable:(NSString *)tableName andTileGenerator: (GPKGTileGenerator *) tileGenerator andLabel: (NSString *) label andUrl: (NSString *) tileUrl{
    
    MCLoadTilesTask * loadTilesTask = [[MCLoadTilesTask alloc] initWithCallback:callback];
    
    [tileGenerator setProgress:loadTilesTask];
    
    [loadTilesTask setTileGenerator:tileGenerator];
    
    UIAlertView *alertView = [[UIAlertView alloc]
                              initWithTitle:[NSString stringWithFormat:@"%@ for %@ into layer: %@", label, geoPackage.name, tableName]
                              message:@""
                              delegate:loadTilesTask
                              cancelButtonTitle:[MCProperties getValueOfProperty:GPKGS_PROP_STOP_LABEL]
                              otherButtonTitles:nil];
    UIProgressView *progressView = [MCUtils buildProgressBarView];
    [alertView setValue:progressView forKey:@"accessoryView"];
    
    loadTilesTask.alertView = alertView;
    loadTilesTask.progressView = progressView;
    
    [alertView show];
    
    loadTilesTask.slowNotifier = [SlowServerNotifier alloc];
    NSArray  *parts = [tileUrl componentsSeparatedByString:@"/"];
    if(parts.count > 2) {
        loadTilesTask.host = parts[2];
    } else {
        loadTilesTask.host = @"this server";
    }
    loadTilesTask.lastProgressTime = CACurrentMediaTime();
    
    [loadTilesTask execute];
    
}

-(instancetype) initWithCallback: (NSObject<GPKGSLoadTilesProtocol> *) callback{
    self = [super init];
    if(self != nil){
        self.callback = callback;
        self.progress = 0;
        self.canceled = false;
    }
    return self;
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(buttonIndex == 0){
        self.canceled = true;
    }
}

-(void) execute{
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        
        int count = 0;
        
        @try {
            count = [self.tileGenerator generateTiles];
            if(count < [self.maxTiles intValue] && [self.tileGenerator class] != [GPKGFeatureTileGenerator class]){
                NSString * countError = [NSString stringWithFormat:@"Fewer tiles were generated than expected. Expected: %@, Actual: %u", self.maxTiles, count];
                if(self.error != nil){
                    countError = [NSString stringWithFormat:@"%@, Error: %@", countError, self.error];
                }
                self.error = countError;
            }
        }
        @catch (NSException *e) {
            self.error = [e description];
        }
        @finally{
            [self.tileGenerator close];
        }
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.alertView dismissWithClickedButtonIndex:-1 animated:true];
            
            if(self.error == nil){
                [self.callback onLoadTilesCompleted:count];
            }else{
                if(self.canceled){
                    [self.callback onLoadTilesCanceled:[self.error description] withCount:count];
                }else{
                    [self.callback onLoadTilesFailure:[self.error description] withCount:count];
                }
            }
        });
        
    });
    
}

-(void) setMax: (int) max{
    self.maxTiles = [NSNumber numberWithInt:max];
    [self addProgress:0];
}

-(void) addProgress: (int) progress{
    double currentTime = CACurrentMediaTime();
    [self.slowNotifier responseTime:currentTime - self.lastProgressTime andHost:self.host];
    self.lastProgressTime = CACurrentMediaTime();
    self.progress += progress;
    float progressPercentage = self.progress / [self.maxTiles floatValue];
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.alertView setMessage:[NSString stringWithFormat:@"%d of %@", self.progress, self.maxTiles]];
        [self.progressView setProgress:progressPercentage];
    });
}

-(BOOL) isActive{
    return !self.canceled;
}

-(BOOL) cleanupOnCancel{
    return false;
}

-(void) completed{
    
}

-(void) failureWithError: (NSString *) error{
    self.error = error;
}

+(GPKGTileScaling *) tileScaling{
    // TODO Set these values from tile creation and updates
    //return [[GPKGTileScaling alloc] initWithScalingType:GPKG_TSC_CLOSEST_IN_OUT andZoomIn:[NSNumber numberWithInt:2] andZoomOut:[NSNumber numberWithInt:2]];
    //return [[GPKGTileScaling alloc] initWithScalingType:GPKG_TSC_CLOSEST_IN_OUT andZoomIn:nil andZoomOut:nil];
    return nil;
}

@end
