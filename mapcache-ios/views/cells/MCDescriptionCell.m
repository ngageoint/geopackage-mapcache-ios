//
//  GPKGSDesctiptionCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/10/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCDescriptionCell.h"

@implementation MCDescriptionCell

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


- (void)textAlignCenter {
    self.descriptionLabel.textAlignment = NSTextAlignmentCenter;
}


- (void)textAlignRight {
    self.descriptionLabel.textAlignment = NSTextAlignmentRight;
}


- (void)textAlignLeft {
    self.descriptionLabel.textAlignment = NSTextAlignmentLeft;
}


- (void)useSecondaryAppearance {
    [self.descriptionLabel setTextColor:[UIColor colorWithRed:0.5 green:0.5 blue:0.5 alpha:1.0]];
}

@end
