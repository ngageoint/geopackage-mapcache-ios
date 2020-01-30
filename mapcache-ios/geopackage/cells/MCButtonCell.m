//
//  GPKGSButtonCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/27/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "MCButtonCell.h"

@implementation MCButtonCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


- (IBAction)buttonTapped:(id)sender {
    [_delegate performButtonAction:_action];
}


- (void) setButtonLabel: (NSString *) text {
    [self.button setTitle:text forState:UIControlStateNormal];
}


- (void) useSecondaryColors {
    [self.button setBackgroundColor:[UIColor clearColor]];
    self.button.clipsToBounds = YES;
    [self.button setTitleColor: [UIColor colorWithRed:15.3/255.0 green:187.5/255.0 blue:186.15/255.0 alpha:1.0] forState:UIControlStateNormal];
}


- (void) enableButton {
    _button.userInteractionEnabled = YES;
    _button.backgroundColor = [MCColorUtil getAccent];
}


- (void) disableButton {
    _button.userInteractionEnabled = NO;
    _button.backgroundColor = [MCColorUtil getAccentLight];
}

@end
