//
//  GPKGSDesctiptionCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/10/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCDesctiptionCell.h"

@implementation MCDesctiptionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


- (void) setDescription: (NSString *) description {
    [self.descriptionLabel setText:description];
    [self.descriptionLabel sizeToFit];
    [self updateConstraintsIfNeeded];
    [self layoutSubviews];
    [self.descriptionLabel layoutIfNeeded];
}

@end
