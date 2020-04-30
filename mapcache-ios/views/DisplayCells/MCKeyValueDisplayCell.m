//
//  MCKeyValueDisplayCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 4/20/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "MCKeyValueDisplayCell.h"

@implementation MCKeyValueDisplayCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)setKeyLabelText:(NSString *)text {
    [self.keyLabel setText:text];
}


- (void)setValueLabelText:(NSString *)text {
    [self.valueLabel setText:text];
}


@end
