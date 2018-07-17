//
//  GPKGSPickerViewCellTableViewCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/23/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCPickerViewCell.h"

@implementation MCPickerViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


@end
