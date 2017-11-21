//
//  GPKGSHeaderCellTableViewCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/17/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "GPKGSHeaderCellTableViewCell.h"

@implementation GPKGSHeaderCellTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    _nameLabel.numberOfLines = 0;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
