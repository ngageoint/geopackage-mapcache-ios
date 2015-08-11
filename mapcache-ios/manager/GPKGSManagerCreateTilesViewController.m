//
//  GPKGSManagerCreateTilesViewController.m
//  mapcache-ios
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
#import "GPKGSLoadTilesTask.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGSUtils.h"

NSString * const GPKGS_MANAGER_CREATE_TILES_SEG_CREATE_TILES = @"createTiles";

@interface GPKGSManagerCreateTilesViewController ()

@end

@implementation GPKGSManagerCreateTilesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.databaseValue setText:self.database.name];
    
    UIToolbar *keyboardToolbar = [GPKGSUtils buildKeyboardDoneToolbarWithTarget:self andAction:@selector(doneButtonPressed)];
    
    self.databaseValue.inputAccessoryView = keyboardToolbar;
}

- (void) doneButtonPressed {
    [self.databaseValue resignFirstResponder];
}

- (IBAction)cancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)createButton:(id)sender {
    
    @try {
        
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
        
        // If not importing tiles, just create the table
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
                [self.delegate createManagerTilesViewController:self createdTiles:0 withError:nil];
            }
            [self dismissViewControllerAnimated:YES completion:nil];
            
        }else{
            // Load tiles
            [GPKGSLoadTilesTask loadTilesWithCallback:self andDatabase:self.database.name andTable:name andUrl:url andMinZoom:minZoom andMaxZoom:maxZoom andCompressFormat:generateTiles.compressFormat andCompressQuality:[generateTiles.compressQuality intValue] andCompressScale:[generateTiles.compressScale intValue] andStandardFormat:generateTiles.standardWebMercatorFormat andBoundingBox:boundingBox andLabel:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_CREATE_TILES_LABEL]];
        }
    
    }
    @catch (NSException *e) {
        if(self.delegate != nil){
            [self.delegate createManagerTilesViewController:self createdTiles:0 withError:[e description]];
        }
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

-(void) onLoadTilesCanceled: (NSString *) result withCount:(int)count{
    if(self.delegate != nil){
        [self.delegate createManagerTilesViewController:self createdTiles:count withError:nil];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) onLoadTilesFailure: (NSString *) result withCount:(int)count{
    if(self.delegate != nil){
        [self.delegate createManagerTilesViewController:self createdTiles:count withError:result];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) onLoadTilesCompleted:(int)count{
    if(self.delegate != nil){
        [self.delegate createManagerTilesViewController:self createdTiles:count withError:nil];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
