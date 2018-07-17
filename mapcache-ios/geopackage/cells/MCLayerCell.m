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
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
