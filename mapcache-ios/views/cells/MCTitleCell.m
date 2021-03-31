//
//  MCTitleCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 12/8/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCTitleCell.h"

@implementation MCTitleCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)setLabelText:(NSString *) text {
    [self.label setText:text];
}

@end
