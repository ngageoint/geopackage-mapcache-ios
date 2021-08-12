//
//  MCDualButtonCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/21/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "MCDualButtonCell.h"

@implementation MCDualButtonCell

- (void)awakeFromNib {
    [super awakeFromNib];
    [self setBackgroundColor:[UIColor clearColor]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    // Initialization code
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


- (IBAction)leftButtonPressed:(id)sender {
    [_dualButtonDelegate performDualButtonAction:self.leftButtonAction];
}


- (IBAction)rightButtonPressed:(id)sender {
    [_dualButtonDelegate performDualButtonAction:self.rightButtonAction];
}


- (void)setLeftButtonLabel: (NSString *) text {
    [_leftButton setTitle:text forState:UIControlStateNormal];
}


- (void)setRightButtonLabel: (NSString *) text {
    [_rightButton setTitle:text forState:UIControlStateNormal];
}


- (void)enableLeftButton {
    [_leftButton setEnabled: YES];
    [_leftButton setBackgroundColor:[MCColorUtil getMediumGrey]];
}


- (void)enableRightButton {
    [_rightButton setEnabled: YES];
    [_rightButton setBackgroundColor:[MCColorUtil getAccent]];
}


- (void)disableLeftButton {
    [_leftButton setEnabled: NO];
    [_leftButton setBackgroundColor:[MCColorUtil getLightGrey]];
}


- (void)disableRightButton {
    [_rightButton setEnabled: NO];
    [_rightButton setBackgroundColor:[MCColorUtil getAccentLight]];
}


- (void)disableButtons {
    [_leftButton setEnabled: NO];
    [_leftButton setBackgroundColor:[MCColorUtil getLightGrey]];
    [_rightButton setEnabled: NO];
    [_rightButton setBackgroundColor:[MCColorUtil getAccentLight]];
}


- (void)enableButtons {
    [_leftButton setEnabled: YES];
    [_leftButton setBackgroundColor:[MCColorUtil getMediumGrey]];
    [_rightButton setEnabled: YES];
    [_rightButton setBackgroundColor:[MCColorUtil getAccent]];
}


- (void)leftButtonUsePrimaryColors {
    [_leftButton setBackgroundColor: [MCColorUtil getAccent]];
    _leftButton.clipsToBounds = YES;
    [_leftButton setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [_leftButton setImage:nil forState:UIControlStateNormal];
}


- (void)leftButtonUseSecondaryColors {
    [_leftButton setBackgroundColor:[UIColor clearColor]];
    _leftButton.clipsToBounds = YES;
    [_leftButton setTitleColor: [UIColor colorWithRed:15.3/255.0 green:187.5/255.0 blue:186.15/255.0 alpha:1.0] forState:UIControlStateNormal];
    [_leftButton setImage:nil forState:UIControlStateNormal];
}


- (void)rightButtonUsePrimaryColors {
    [_rightButton setBackgroundColor: [MCColorUtil getAccent]];
    _rightButton.clipsToBounds = YES;
    [_rightButton setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
    [_rightButton setImage:nil forState:UIControlStateNormal];
}


- (void)rightButtonUseSecondaryColors {
    [_rightButton setBackgroundColor:[UIColor clearColor]];
    _rightButton.clipsToBounds = YES;
    [_rightButton setTitleColor: [UIColor colorWithRed:15.3/255.0 green:187.5/255.0 blue:186.15/255.0 alpha:1.0] forState:UIControlStateNormal];
    [_rightButton setImage:nil forState:UIControlStateNormal];
}


- (void)leftButtonUseClearBackground {
    [self.leftButton setBackgroundColor:UIColor.clearColor];
}


- (void)rightButtonUseClearBackground {
    [self.rightButton setBackgroundColor:UIColor.clearColor];
}


@end
