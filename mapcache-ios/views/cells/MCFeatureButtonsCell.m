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
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (IBAction)editButtonTapped:(id)sender {
    [_delegate editLayer];
}


- (IBAction)indexButtonTapped:(id)sender {
    [_delegate indexLayer];
}


- (IBAction)overlayButtonTapped:(id)sender {
    [_delegate createOverlay];
}


- (IBAction)createTilesButtonTapped:(id)sender {
    [_delegate createOverlay];
}


- (IBAction)deleteButtonTapped:(id)sender {
    [_delegate deleteLayer];
}


@end
