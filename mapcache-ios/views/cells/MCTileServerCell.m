//
//  MCTileServerCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/28/21.
//  Copyright © 2021 NGA. All rights reserved.
//

#import "MCTileServerCell.h"
#import"mapcache_ios-Swift.h"

@interface MCTileServerCell()
@property (nonatomic, strong) MCTileServer *tileServer;
@end

@implementation MCTileServerCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.visibilityStatusIndicator.image = [UIImage imageNamed:@"allLayersOn"];
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


- (void)setContentWithTileServer:(MCTileServer *)tileServer {
    self.tileServer = tileServer;
    [self.nameLabel setText:self.tileServer.serverName];
    [self.urlLabel setText:self.tileServer.url];
    
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