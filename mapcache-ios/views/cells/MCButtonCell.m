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


- (void) usePrimaryColors {
    [self.button setBackgroundColor: [UIColor colorNamed:@"ngaButtonColor"]];
    self.button.clipsToBounds = YES;
    [self.button setTitleColor: [UIColor whiteColor] forState:UIControlStateNormal];
}


- (void) useSecondaryColors {
    [self.button setBackgroundColor:[UIColor clearColor]];
    self.button.clipsToBounds = YES;
    [self.button setTitleColor: [UIColor colorNamed:@"ngaButtonColor"] forState:UIControlStateNormal];
}


- (void) useRedColor {
    [self.button setBackgroundColor:[UIColor redColor]];
    self.button.clipsToBounds = YES;
    [self.button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}


- (void) useSecondaryRed {
    [self.button setBackgroundColor:[UIColor clearColor]];
    self.button.clipsToBounds = YES;
    [self.button setTitleColor: [UIColor redColor] forState:UIControlStateNormal];
}


- (void) enableButton {
    _button.userInteractionEnabled = YES;
    [_button setBackgroundColor: [UIColor colorNamed:@"ngaButtonColor"]];
}


- (void) disableButton {
    _button.userInteractionEnabled = NO;
    [_button setBackgroundColor: [UIColor colorNamed:@"ngaDisabledButtonColor"]];
}

@end
