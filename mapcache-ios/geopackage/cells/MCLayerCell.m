//
//  GPKGSLayerCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/21/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "MCLayerCell.h"

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
