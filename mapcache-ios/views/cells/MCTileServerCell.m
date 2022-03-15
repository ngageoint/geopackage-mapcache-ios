//
//  MCTileServerCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/28/21.
//  Copyright © 2021 NGA. All rights reserved.
//

#import "MCTileServerCell.h"
#import"mapcache_ios-Swift.h"

@implementation MCTileServerCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.visibilityStatusIndicator.image = [UIImage imageNamed:@"allLayersOn"];
    self.backgroundColor = [UIColor colorNamed:@"ngaBackgroundColor"];
    self.layersExpanded = NO;
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


- (void)setContentWithTileServer:(MCTileServer *)tileServer {
    self.tileServer = tileServer;
    [self.nameLabel setText:self.tileServer.serverName];
    
    if ([self.tileServer.serverName isEqualToString:self.tileServer.url]) {
        [self.urlLabel setText:@""];
    } else {
        [self.urlLabel setText:self.tileServer.url];
    }
    
    [self.icon setImage:[UIImage imageNamed:[MCProperties getValueOfProperty:GPKGS_PROP_ICON_TILE_SERVER]]];
    
    if (self.tileServer.serverType == MCTileServerTypeXyz) {
        [self.layersLabel setText:@"1 layer"];
    } else {
        NSString *layerWord = self.tileServer.layers.count == 1 ? @"layer" : @"layers";
        [self.layersLabel setText:[NSString stringWithFormat:@"%lu %@", (unsigned long)self.tileServer.layers.count, layerWord]];
    }
}


- (void) setNameLabelText:(NSString *)serverName {
    [self.nameLabel setText:serverName];
}


- (void) setUrlLabelText:(NSString *)url {
    [self.urlLabel setText:url];
}


- (void) setLayersLabelText:(NSString *)layersText {
    [self.layersLabel setText:layersText];
}


- (void)activeIndicatorOn {
    [self.visibilityStatusIndicator setHidden:NO];
}


- (void)activeIndicatorOff {
    [self.visibilityStatusIndicator setHidden:YES];
}


- (void)toggleActiveIndicator {
    if (self.visibilityStatusIndicator.isHidden) {
        [self.visibilityStatusIndicator setHidden:NO];
    } else {
        [self.visibilityStatusIndicator setHidden:YES];
    }
}

@end
