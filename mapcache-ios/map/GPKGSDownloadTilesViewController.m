//
//  GPKGSDownloadTilesViewController.m
//  mapcache-ios
//
//  Created by Brian Osborn on 8/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSDownloadTilesViewController.h"
#import "GPKGSUtils.h"
#import "GPKGSCreateTilesViewController.h"
#import "GPKGProjectionTransform.h"
#import "GPKGProjectionConstants.h"
#import "GPKGTileBoundingBoxUtils.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGSLoadTilesTask.h"

NSString * const GPKGS_DOWNLOAD_TILES_SEG_CREATE_TILES = @"createTiles";

@interface GPKGSDownloadTilesViewController ()

@property (nonatomic, strong) NSArray * existing;

@end

@implementation GPKGSDownloadTilesViewController

#define TAG_EXISTING_GEOPACKAGES 1

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIToolbar *keyboardToolbar = [GPKGSUtils buildKeyboardDoneToolbarWithTarget:self andAction:@selector(doneButtonPressed)];
    
    self.databaseValue.inputAccessoryView = keyboardToolbar;
}

- (void) doneButtonPressed {
    [self.databaseValue resignFirstResponder];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch(alertView.tag){
            
        case TAG_EXISTING_GEOPACKAGES:
            if(buttonIndex >= 0){
                if(buttonIndex < [self.existing count]){
                    NSString * database = [self.existing objectAtIndex:buttonIndex];
                    [self.databaseValue setText:database];
                }
            }
            
            break;
    }
    
}

- (IBAction)cancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)existingButton:(id)sender {
    
    self.existing = [self.manager databases];
    
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_CREATE_TILES_EXISTING_GEOPACKAGE_DIALOG_LABEL]
                          message:nil
                          delegate:self
                          cancelButtonTitle:nil
                          otherButtonTitles:nil];
    
    for (NSString *database in self.existing) {
        [alert addButtonWithTitle:database];
    }
    alert.cancelButtonIndex = [alert addButtonWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]];
    
    alert.tag = TAG_EXISTING_GEOPACKAGES;
    
    [alert show];
}

- (IBAction)downloadButton:(id)sender {
    
    @try {
        
        NSString * database = self.databaseValue.text;
        if(database == nil || [database length] == 0){
            [NSException raise:@"GeoPackage" format:@"GeoPackage is required"];
        }
        
        NSString * tableName = self.data.name;
        if(tableName == nil || [tableName length] == 0){
            [NSException raise:@"Table Name" format:@"Table Name is required"];
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
        
        // Create the database if it doesn't exist
        if(![self.manager exists:database]){
            [self.manager create:database];
        }
        
        GPKGTileScaling *scaling = [GPKGSLoadTilesTask tileScaling];
        
        // Load tiles
        [GPKGSLoadTilesTask loadTilesWithCallback:self andDatabase:database andTable:tableName andUrl:url andMinZoom:minZoom andMaxZoom:maxZoom andCompressFormat:generateTiles.compressFormat andCompressQuality:[generateTiles.compressQuality intValue] andCompressScale:[generateTiles.compressScale intValue] andStandardFormat:generateTiles.standardWebMercatorFormat andBoundingBox:boundingBox andTileScaling:scaling andAuthority:PROJ_AUTHORITY_EPSG andCode:[NSString stringWithFormat:@"%d",loadTiles.epsg] andLabel:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_CREATE_TILES_DIALOG_LABEL]];
        
    }
    @catch (NSException *e) {
        if(self.delegate != nil){
            [self.delegate downloadTilesViewController:self downloadedTiles:0 withError:[e description]];
        }
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([segue.identifier isEqualToString:GPKGS_DOWNLOAD_TILES_SEG_CREATE_TILES])
    {
        GPKGSCreateTilesViewController *createTilesViewController = segue.destinationViewController;
        createTilesViewController.data = self.data;
        
        // Try to find a good zoom starting point
        if(self.data.loadTiles.generateTiles.boundingBox != nil){
            
            GPKGProjectionTransform * webMercatorTransform = [[GPKGProjectionTransform alloc] initWithFromEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM andToEpsg:PROJ_EPSG_WEB_MERCATOR];
            GPKGBoundingBox * webMercatorBoundingBox = [webMercatorTransform transformWithBoundingBox:self.data.loadTiles.generateTiles.boundingBox ];
            int zoomLevel = [GPKGTileBoundingBoxUtils getZoomLevelWithWebMercatorBoundingBox:webMercatorBoundingBox];
            int maxZoomLevel = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_LOAD_TILES_MAX_ZOOM_DEFAULT] intValue];
            zoomLevel = MAX(0, MIN(zoomLevel, maxZoomLevel - 2));
            self.data.loadTiles.generateTiles.minZoom = [NSNumber numberWithInt:zoomLevel];
            self.data.loadTiles.generateTiles.maxZoom = [NSNumber numberWithInt:maxZoomLevel];
            self.data.loadTiles.generateTiles.setZooms = false;
        }
    }
}

-(void) onLoadTilesCanceled: (NSString *) result withCount:(int)count{
    if(self.delegate != nil){
        [self.delegate downloadTilesViewController:self downloadedTiles:count withError:nil];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) onLoadTilesFailure: (NSString *) result withCount:(int)count{
    if(self.delegate != nil){
        [self.delegate downloadTilesViewController:self downloadedTiles:count withError:result];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void) onLoadTilesCompleted:(int)count{
    if(self.delegate != nil){
        [self.delegate downloadTilesViewController:self downloadedTiles:count withError:nil];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
