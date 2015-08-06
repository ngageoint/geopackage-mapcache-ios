//
//  GPKGSManagerEditTileOverlayViewController.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/29/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSManagerEditTileOverlayViewController.h"
#import "GPKGSEditTileOverlayData.h"
#import "GPKGSEditTileOverlayViewController.h"

NSString * const GPKGS_EDIT_TILE_OVERLAY_SEG_EDIT_TILE_OVERLAY = @"editTileOverlay";

@interface GPKGSManagerEditTileOverlayViewController ()

@property (nonatomic, strong) GPKGSEditTileOverlayData *editTileOverlayData;

@end

@implementation GPKGSManagerEditTileOverlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (IBAction)cancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)editButton:(id)sender {
    
    [self.table setMinZoom:[self.editTileOverlayData.minZoom intValue]];
    [self.table setMaxZoom:[self.editTileOverlayData.maxZoom intValue]];
    [self.table setMinLat:[self.editTileOverlayData.boundingBox.minLatitude doubleValue]];
    [self.table setMaxLat:[self.editTileOverlayData.boundingBox.maxLatitude doubleValue]];
    [self.table setMinLon:[self.editTileOverlayData.boundingBox.minLongitude doubleValue]];
    [self.table setMaxLon:[self.editTileOverlayData.boundingBox.maxLongitude doubleValue]];
    [self.table setPointColor:[self.editTileOverlayData.featureTilesDraw getPointAlphaColor]];
    [self.table setPointColorName:self.editTileOverlayData.featureTilesDraw.pointColorName];
    [self.table setPointAlpha:[self.editTileOverlayData.featureTilesDraw.pointAlpha intValue]];
    [self.table setPointRadius:[self.editTileOverlayData.featureTilesDraw.pointRadius doubleValue]];
    [self.table setLineColor:[self.editTileOverlayData.featureTilesDraw getLineAlphaColor]];
    [self.table setLineColorName:self.editTileOverlayData.featureTilesDraw.lineColorName];
    [self.table setLineAlpha:[self.editTileOverlayData.featureTilesDraw.lineAlpha intValue]];
    [self.table setLineStroke:[self.editTileOverlayData.featureTilesDraw.lineStroke doubleValue]];
    [self.table setPolygonColor:[self.editTileOverlayData.featureTilesDraw getPolygonAlphaColor]];
    [self.table setPolygonColorName:self.editTileOverlayData.featureTilesDraw.polygonColorName];
    [self.table setPolygonAlpha:[self.editTileOverlayData.featureTilesDraw.polygonAlpha intValue]];
    [self.table setPolygonStroke:[self.editTileOverlayData.featureTilesDraw.polygonStroke doubleValue]];
    [self.table setPolygonFill:self.editTileOverlayData.featureTilesDraw.polygonFill];
    [self.table setPolygonFillColor:[self.editTileOverlayData.featureTilesDraw getPolygonFillAlphaColor]];
    [self.table setPolygonFillColorName:self.editTileOverlayData.featureTilesDraw.polygonFillColorName];
    [self.table setPolygonFillAlpha:[self.editTileOverlayData.featureTilesDraw.polygonFillAlpha intValue]];
    
    if(self.delegate != nil){
        [self.delegate editTileOverlayViewController:self featureOverlayTable:self.table];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([segue.identifier isEqualToString:GPKGS_EDIT_TILE_OVERLAY_SEG_EDIT_TILE_OVERLAY])
    {
        [self prepareEditTileOverlayData];
        GPKGSEditTileOverlayViewController *editTileOverlayViewController = segue.destinationViewController;
        editTileOverlayViewController.data = self.editTileOverlayData;
        editTileOverlayViewController.manager = self.manager;
        editTileOverlayViewController.database = self.table.database;
        editTileOverlayViewController.featureTable = self.table.featureTable;
    }
}

-(void)prepareEditTileOverlayData{
    self.editTileOverlayData = [[GPKGSEditTileOverlayData alloc] init];
    
    [self.editTileOverlayData setMinZoom:[NSNumber numberWithInt:self.table.minZoom]];
    [self.editTileOverlayData setMaxZoom:[NSNumber numberWithInt:self.table.maxZoom]];
    GPKGBoundingBox * boundingBox = [[GPKGBoundingBox alloc] initWithMinLongitudeDouble:self.table.minLon andMaxLongitudeDouble:self.table.maxLon andMinLatitudeDouble:self.table.minLat andMaxLatitudeDouble:self.table.maxLat];
    [self.editTileOverlayData setBoundingBox:boundingBox];
    GPKGSFeatureTilesDrawData * featureTilesDraw = [[GPKGSFeatureTilesDrawData alloc] init];
    [featureTilesDraw setPointColorName:self.table.pointColorName];
    [featureTilesDraw setPointAlpha:[NSNumber numberWithInt:self.table.pointAlpha]];
    [featureTilesDraw setPointRadius:[[NSDecimalNumber alloc] initWithDouble:self.table.pointRadius]];
    [featureTilesDraw setLineColorName:self.table.lineColorName];
    [featureTilesDraw setLineAlpha:[NSNumber numberWithInt:self.table.lineAlpha]];
    [featureTilesDraw setLineStroke:[[NSDecimalNumber alloc] initWithDouble:self.table.lineStroke]];
    [featureTilesDraw setPolygonColorName:self.table.polygonColorName];
    [featureTilesDraw setPolygonAlpha:[NSNumber numberWithInt:self.table.polygonAlpha]];
    [featureTilesDraw setPolygonStroke:[[NSDecimalNumber alloc] initWithDouble:self.table.polygonStroke]];
    [featureTilesDraw setPolygonFill:self.table.polygonFill];
    [featureTilesDraw setPolygonFillColorName:self.table.polygonFillColorName];
    [featureTilesDraw setPolygonFillAlpha:[NSNumber numberWithInt:self.table.polygonFillAlpha]];
    [self.editTileOverlayData setFeatureTilesDraw:featureTilesDraw];
}

@end
