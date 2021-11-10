//
//  MCFeatureButtonsCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 7/9/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCFeatureLayerOperationsCell.h"

@implementation MCFeatureLayerOperationsCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (IBAction)renameLayer:(id)sender {
    [_delegate renameFeatureLayer];
}


- (IBAction)indexFeatures:(id)sender {
    [_delegate indexFeatures];
}


- (IBAction)createTiles:(id)sender {
    [_delegate createTiles];
}


- (IBAction)createOverlay:(id)sender {
    [_delegate createOverlay];
}


- (IBAction)deleteFeatureLayer:(id)sender {
    [_delegate deleteFeatureLayer];
}


@end
