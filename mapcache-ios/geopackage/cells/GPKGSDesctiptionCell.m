//
//  GPKGSDesctiptionCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/10/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "GPKGSDesctiptionCell.h"

@implementation GPKGSDesctiptionCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
