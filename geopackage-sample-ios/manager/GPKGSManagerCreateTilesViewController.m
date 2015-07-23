//
//  GPKGSManagerCreateTilesViewController.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/22/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSManagerCreateTilesViewController.h"
#import "GPKGSCreateTilesViewController.h"
#import "GPKGUrlTileGenerator.h"
#import "GPKGProjectionTransform.h"
#import "GPKGProjectionConstants.h"
#import "GPKGTileBoundingBoxUtils.h"

NSString * const GPKGS_MANAGER_CREATE_TILES_SEG_CREATE_TILES = @"createTiles";

@interface GPKGSManagerCreateTilesViewController ()

@end

@implementation GPKGSManagerCreateTilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.databaseValue setText:self.database.name];
}

- (IBAction)cancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)createButton:(id)sender {
    
    @try {
    
    int count = 0;
        
        NSString * name = self.data.name;
        
        if(name == nil || [name length] == 0){
            [NSException raise:@"Table Name" format:@"Table name is required"];
        }
        
        GPKGSLoadTilesData * loadTiles = self.data.loadTiles;
        NSString * url = loadTiles.url;
        
        GPKGSGenerateTilesData * generateTiles = loadTiles.generateTiles;
        int minZoom = [generateTiles.minZoom intValue];
        int maxZoom = [generateTiles.maxZoom intValue];
        
        if (minZoom > maxZoom) {
            [NSException raise:@"Zoom Range" format:@"Min zoom (%d) can not be larger than max zoom (%d)", minZoom, maxZoom];
        }
        
        GPKGBoundingBox * boundingBox = generateTiles.boundingBox;
        
        if ([boundingBox.minLatitude doubleValue] > [boundingBox.maxLatitude doubleValue]) {
            [NSException raise:@"Latitude Range" format:@"Min latitude (%@) can not be larger than max latitude (%@)", boundingBox.minLatitude, boundingBox.maxLatitude];
        }
        
        if ([boundingBox.minLongitude doubleValue] > [boundingBox.maxLongitude doubleValue]) {
            [NSException raise:@"Longitude Range" format:@"Min longitude (%@) can not be larger than max longitude (%@)", boundingBox.minLongitude, boundingBox.maxLongitude];
        }
        
        if(url == nil || [url length] == 0){
            
            GPKGBoundingBox * webMercatorBoundingBox = [GPKGTileBoundingBoxUtils toWebMercatorWithBoundingBox:boundingBox];
            
            GPKGGeoPackage * geoPackage = [self.manager open:self.database.name];
            @try {
                // Create the web mercator srs if needed
                GPKGSpatialReferenceSystemDao * srsDao = [geoPackage getSpatialReferenceSystemDao];
                [srsDao getOrCreateWithSrsId:[NSNumber numberWithInt:PROJ_EPSG_WEB_MERCATOR]];
                // Create the tile table
                [geoPackage createTileTableWithTableName:name andContentsBoundingBox:boundingBox andContentsSrsId:[NSNumber numberWithInt:PROJ_EPSG_WORLD_GEODETIC_SYSTEM] andTileMatrixSetBoundingBox:webMercatorBoundingBox andTileMatrixSetSrsId:[NSNumber numberWithInt:PROJ_EPSG_WEB_MERCATOR]];
            }
            @finally {
                [geoPackage close];
            }

            if(self.delegate != nil){
                [self.delegate createManagerTilesViewController:self createdTiles:true withError:nil];
            }
            
        }else{
        
            // TODO change this to be a tile generator task
            GPKGGeoPackage * geoPackage = [self.manager open:self.database.name];
            @try {
            
                GPKGTileGenerator * tileGenerator = [[GPKGUrlTileGenerator alloc] initWithGeoPackage:geoPackage andTableName:name andTileUrl:url andMinZoom:minZoom andMaxZoom:maxZoom];
                
                [tileGenerator setCompressFormat:generateTiles.compressFormat];
                [tileGenerator setCompressQualityAsIntPercentage:[generateTiles.compressQuality intValue]];
                [tileGenerator setCompressScaleAsIntPercentage:[generateTiles.compressScale intValue]];
                [tileGenerator setTileBoundingBox:boundingBox];
                [tileGenerator setStandardWebMercatorFormat:generateTiles.standardWebMercatorFormat];
                
                count = [tileGenerator generateTiles];
            }
            @finally {
                [geoPackage close];
            }
            
            if(self.delegate != nil){
                [self.delegate createManagerTilesViewController:self createdTiles:true withError:nil];
            }
        }
    
    }
    @catch (NSException *e) {
        if(self.delegate != nil){
            [self.delegate createManagerTilesViewController:self createdTiles:false withError:[e description]];
        }
    }
    @finally{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([segue.identifier isEqualToString:GPKGS_MANAGER_CREATE_TILES_SEG_CREATE_TILES])
    {
        GPKGSCreateTilesViewController *createTilesViewController = segue.destinationViewController;
        createTilesViewController.data = self.data;
    }
}

@end
