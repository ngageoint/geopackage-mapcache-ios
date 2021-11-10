//
//  MCTileButtonsCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 7/19/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCTileLayerOperationsCell.h"

@implementation MCTileLayerOperationsCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (IBAction)rename:(id)sender {
    [_delegate renameTileLayer];
}


- (IBAction)scaling:(id)sender {
    [_delegate showScalingOptions];
}


- (IBAction)deleteTileLayer:(id)sender {
    [_delegate deleteTileLayer];
}

@end
