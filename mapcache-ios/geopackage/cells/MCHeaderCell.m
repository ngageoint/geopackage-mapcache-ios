//
//  GPKGSHeaderCellTableViewCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/17/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "MCConstants.h"
#import "MCHeaderCell.h"

@implementation MCHeaderCell

- (void)awakeFromNib {
    [super awakeFromNib];
    _nameLabel.numberOfLines = 0;
    [self setBackgroundColor:[UIColor clearColor]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


- (void)setNameLabelText:(NSString *) text {
    [self.nameLabel setText:text];
}


- (void)setDetailLabelOneText:(NSString *) text {
    [self.detailLabelOne setText:text];
}


- (void)setDetailLabelTwoText:(NSString *) text {
    [self.detailLabelTwo setText:text];
}


- (void)setDetailLabelThreeText:(NSString *) text {
    [self.detailLabelThree setText:text];
}



@end
