//
//  MCEmptyStateCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/1/19.
//  Copyright © 2019 NGA. All rights reserved.
//

#import "MCEmptyStateCell.h"

@implementation MCEmptyStateCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


- (void) useAsSpacer {
    [self.logoImageView setHidden:YES];
    [self.titleLabel setHidden:YES];
    [self.detailLabel setHidden:YES];
}
 

@end
