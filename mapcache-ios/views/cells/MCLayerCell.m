//
//  GPKGSLayerCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/21/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "MCLayerCell.h"
#import"mapcache_ios-Swift.h"

@implementation MCLayerCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    [self.activeIndicator setImage:[UIImage imageNamed: @"layerActiveIndicator"]];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


/**
    Use a GeoPackage table, which represents a map layer, for this cell's information.
 */
- (void)setContentsWithTable:(MCTable *) table{
    self.table = table;
    [self.layerNameLabel setText:table.name];
    
    NSString *typeImageName = @"";
    if ([table isMemberOfClass:[MCFeatureTable class]]) {
        typeImageName = [MCProperties getValueOfProperty:GPKGS_PROP_ICON_GEOMETRY];
        [self.detailLabel setText: [NSString stringWithFormat:@"%d features", [(MCFeatureTable *)table count]]];
    } else if ([table isMemberOfClass:[MCTileTable class]]) {
        typeImageName = [MCProperties getValueOfProperty:GPKGS_PROP_ICON_TILES];
        [self.detailLabel setText:[NSString stringWithFormat:@"Zoom levels %d - %d",  [(MCTileTable *)table minZoom], [(MCTileTable *)table maxZoom]]];
    }
    
    [self.layerTypeImage setImage:[UIImage imageNamed:typeImageName]];
}


/**
    Use a WMS layer for this cell's details.
 */
- (void)setContentsWithLayer:(MCLayer *) layer tileServer:(MCTileServer *) tileServer {
    self.mapLayer = layer;
    self.tileServer = tileServer;
    
    NSString *layerTitle = @"";
    for (NSString *title in layer.titles) {
        layerTitle = [NSString stringWithFormat:@"%@ %@", layerTitle, title];
    }
    
    [self.layerNameLabel setText: layerTitle];
    [self.layerTypeImage setImage:[UIImage imageNamed:@"Layer"]];
    [self activeIndicatorOff];
}


- (void) setName: (NSString *) name {
    [self.layerNameLabel setText:name];
}


- (void) setDetails: (NSString *) details {
    [self.detailLabel setText:details];
}


- (void)activeIndicatorOn {
    [self.activeIndicator setHidden:NO];
}


- (void)activeIndicatorOff {
    [self.activeIndicator setHidden:YES];
}


- (void)toggleActiveIndicator {
    if (self.activeIndicator.isHidden) {
        [self.activeIndicator setHidden:NO];
    } else {
        [self.activeIndicator setHidden:YES];
    }
}

@end
