//
//  GPKGSAddTileOverlayViewController.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/29/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSAddTileOverlayViewController.h"
#import "GPKGSEditTileOverlayData.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGSUtils.h"
#import "GPKGSEditTileOverlayViewController.h"
#import "GPKGSFeatureOverlayTable.h"

NSString * const GPKGS_ADD_TILE_OVERLAY_SEG_EDIT_TILE_OVERLAY = @"editTileOverlay";

@interface GPKGSAddTileOverlayViewController ()

@property (nonatomic, strong) GPKGSEditTileOverlayData *editTileOverlayData;

@end

@implementation GPKGSAddTileOverlayViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.databaseValue setText:self.table.database];
    
    // Set a default name
    [self.nameValue setText:[NSString stringWithFormat:@"%@%@", self.table.name, [GPKGSProperties getValueOfProperty:GPKGS_PROP_FEATURE_OVERLAY_TILES_NAME_SUFFIX]]];
    
    UIToolbar *keyboardToolbar = [GPKGSUtils buildKeyboardDoneToolbarWithTarget:self andAction:@selector(doneButtonPressed)];
    
    self.nameValue.inputAccessoryView = keyboardToolbar;
}

- (void) doneButtonPressed {
    [self.nameValue resignFirstResponder];
}

- (IBAction)cancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)addButton:(id)sender {
    
    GPKGSFeatureOverlayTable * overlayTable = [[GPKGSFeatureOverlayTable alloc] initWithDatabase:self.table.database andName:self.nameValue.text andFeatureTable:self.table.name andGeometryType:WKB_NONE andCount:0];
    
    [overlayTable setMinZoom:[self.editTileOverlayData.minZoom intValue]];
    [overlayTable setMaxZoom:[self.editTileOverlayData.maxZoom intValue]];
    [overlayTable setMinLat:[self.editTileOverlayData.boundingBox.minLatitude doubleValue]];
    [overlayTable setMaxLat:[self.editTileOverlayData.boundingBox.maxLatitude doubleValue]];
    [overlayTable setMinLon:[self.editTileOverlayData.boundingBox.minLongitude doubleValue]];
    [overlayTable setMaxLon:[self.editTileOverlayData.boundingBox.maxLongitude doubleValue]];
    [overlayTable setPointColor:[self.editTileOverlayData.featureTilesDraw getPointAlphaColor]];
    [overlayTable setPointColorName:self.editTileOverlayData.featureTilesDraw.pointColorName];
    [overlayTable setPointAlpha:[self.editTileOverlayData.featureTilesDraw.pointAlpha intValue]];
    [overlayTable setPointRadius:[self.editTileOverlayData.featureTilesDraw.pointRadius doubleValue]];
    [overlayTable setLineColor:[self.editTileOverlayData.featureTilesDraw getLineAlphaColor]];
    [overlayTable setLineColorName:self.editTileOverlayData.featureTilesDraw.lineColorName];
    [overlayTable setLineAlpha:[self.editTileOverlayData.featureTilesDraw.lineAlpha intValue]];
    [overlayTable setLineStroke:[self.editTileOverlayData.featureTilesDraw.lineStroke doubleValue]];
    [overlayTable setPolygonColor:[self.editTileOverlayData.featureTilesDraw getPolygonAlphaColor]];
    [overlayTable setPolygonColorName:self.editTileOverlayData.featureTilesDraw.polygonColorName];
    [overlayTable setPolygonAlpha:[self.editTileOverlayData.featureTilesDraw.polygonAlpha intValue]];
    [overlayTable setPolygonStroke:[self.editTileOverlayData.featureTilesDraw.polygonStroke doubleValue]];
    [overlayTable setPolygonFill:self.editTileOverlayData.featureTilesDraw.polygonFill];
    [overlayTable setPolygonFillColor:[self.editTileOverlayData.featureTilesDraw getPolygonFillAlphaColor]];
    [overlayTable setPolygonFillColorName:self.editTileOverlayData.featureTilesDraw.polygonFillColorName];
    [overlayTable setPolygonFillAlpha:[self.editTileOverlayData.featureTilesDraw.polygonFillAlpha intValue]];
    
    if(self.delegate != nil){
        [self.delegate addTileOverlayViewController:self featureOverlayTable:overlayTable];
    }
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([segue.identifier isEqualToString:GPKGS_ADD_TILE_OVERLAY_SEG_EDIT_TILE_OVERLAY])
    {
        self.editTileOverlayData = [[GPKGSEditTileOverlayData alloc] init];
        GPKGSEditTileOverlayViewController *editTileOverlayViewController = segue.destinationViewController;
        editTileOverlayViewController.data = self.editTileOverlayData;
        editTileOverlayViewController.manager = self.manager;
        editTileOverlayViewController.database = self.table.database;
        editTileOverlayViewController.featureTable = self.table.name;
    }
}

@end
