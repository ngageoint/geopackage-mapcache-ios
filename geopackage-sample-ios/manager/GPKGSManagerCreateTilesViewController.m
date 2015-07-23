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

NSString * const GPKGS_MANAGER_CREATE_TILES_SEG_CREATE_TILES = @"createTiles";

@interface GPKGSManagerCreateTilesViewController ()

@end

@implementation GPKGSManagerCreateTilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)cancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)createButton:(id)sender {
    
    int count = 0;
    GPKGGeoPackage * geoPackage = [self.manager open:self.database.name];
    @try {
        
        NSString * name = self.data.name;
        
        GPKGSLoadTilesData * loadTiles = self.data.loadTiles;
        NSString * url = loadTiles.url;
        
        GPKGSGenerateTilesData * generateTiles = loadTiles.generateTiles;
        int minZoom = [generateTiles.minZoom intValue];
        int maxZoom = [generateTiles.maxZoom intValue];
        
        if (minZoom > maxZoom) {
            [NSException raise:@"Zoom Range" format:@"Min zoom (%d) can not be larger than max zoom (%d)", minZoom, maxZoom];
        }
        
        name = @"testtiles";
        url = @"http://osm.geointapps.org/osm/{z}/{x}/{y}.png";
        
        GPKGTileGenerator * tileGenerator = [[GPKGUrlTileGenerator alloc] initWithGeoPackage:geoPackage andTableName:name andTileUrl:url andMinZoom:minZoom andMaxZoom:maxZoom];
        
        [tileGenerator setCompressFormat:generateTiles.compressFormat];
        [tileGenerator setCompressQualityAsIntPercentage:[generateTiles.compressQuality intValue]];
        [tileGenerator setCompressScaleAsIntPercentage:[generateTiles.compressScale intValue]];
        [tileGenerator setTileBoundingBox:generateTiles.boundingBox];
        [tileGenerator setStandardWebMercatorFormat:generateTiles.standardWebMercatorFormat];
        
        count = [tileGenerator generateTiles];
    }
    @finally {
        [geoPackage close];
    }
    
    [self.delegate createManagerTilesViewController:self createdTiles:true withError:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([segue.identifier isEqualToString:GPKGS_MANAGER_CREATE_TILES_SEG_CREATE_TILES])
    {
        GPKGSCreateTilesViewController *createTilesViewController = segue.destinationViewController;
        createTilesViewController.data = self.data;
    }
}

@end
