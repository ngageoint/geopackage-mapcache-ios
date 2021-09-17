//
//  GPKGSManagerLoadTilesViewController.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/27/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSManagerLoadTilesViewController.h"
#import "GPKGSLoadTilesViewController.h"
#import "GPKGUrlTileGenerator.h"
#import "PROJProjectionConstants.h"
#import "GPKGTileBoundingBoxUtils.h"
#import "GPKGSLoadTilesTask.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "PROJProjectionFactory.h"
#import "GPKGTileTableScaling.h"

NSString * const GPKGS_MANAGER_LOAD_TILES_SEG_LOAD_TILES = @"loadTiles";

@implementation GPKGSManagerLoadTilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)cancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)loadButton:(id)sender {
    
    @try {
        
        NSString * name = self.table.name;
        
        GPKGSLoadTilesData * loadTiles = self.data;
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
        
        // If not importing tiles, just create the table
        if(url == nil || [url length] == 0){
            
            GPKGGeoPackage * geoPackage = [self.manager open:self.table.database];
            @try {
                // Create the srs if needed
                GPKGSpatialReferenceSystemDao * srsDao = [geoPackage spatialReferenceSystemDao];
                GPKGSpatialReferenceSystem * srs = [srsDao srsWithEpsg:[NSNumber numberWithInt:loadTiles.epsg]];
                // Create the tile table
                PROJProjection * projection = [PROJProjectionFactory projectionWithEpsgInt:loadTiles.epsg];
                GPKGBoundingBox * bbox = [GPKGSLoadTilesTask transformBoundingBox:boundingBox withProjection:projection];
                [geoPackage createTileTableWithMetadata:[GPKGTileTableMetadata createWithTable:name andTileBoundingBox:bbox andTileSrsId:srs.srsId]];
            }
            @finally {
                [geoPackage close];
            }
            
            if(self.delegate != nil){
                [self.delegate loadManagerTilesViewController:self loadedTiles:0 withError:nil];
            }
            [self dismissViewControllerAnimated:YES completion:nil];
            
        }else{
            // Load tiles
            [GPKGSLoadTilesTask loadTilesWithCallback:self andDatabase:self.table.database andTable:name andUrl:url andMinZoom:minZoom andMaxZoom:maxZoom andCompressFormat:generateTiles.compressFormat andCompressQuality:[generateTiles.compressQuality intValue] andCompressScale:[generateTiles.compressScale intValue] andXyzTiles:generateTiles.xyzTiles andBoundingBox:boundingBox andTileScaling:nil andAuthority:PROJ_AUTHORITY_EPSG andCode:[NSString stringWithFormat:@"%d",loadTiles.epsg] andLabel:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_TILES_LOAD_LABEL]];
        }
        
    }
    @catch (NSException *e) {
        if(self.delegate != nil){
            [self.delegate loadManagerTilesViewController:self loadedTiles:0 withError:[e description]];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([segue.identifier isEqualToString:GPKGS_MANAGER_LOAD_TILES_SEG_LOAD_TILES])
    {
        GPKGSLoadTilesViewController *loadTilesViewController = segue.destinationViewController;
        loadTilesViewController.data = self.data;
    }
}

-(void) onLoadTilesCanceled: (NSString *) result withCount:(int)count{
    if(self.delegate != nil){
        [self.delegate loadManagerTilesViewController:self loadedTiles:count withError:nil];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) onLoadTilesFailure: (NSString *) result withCount:(int)count{
    if(self.delegate != nil){
        [self.delegate loadManagerTilesViewController:self loadedTiles:count withError:result];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) onLoadTilesCompleted:(int)count{
    if(self.delegate != nil){
        [self.delegate loadManagerTilesViewController:self loadedTiles:count withError:nil];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
