//
//  MCSwitchCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 6/19/19.
//  Copyright © 2019 NGA. All rights reserved.
//

#import "MCSwitchCell.h"

@implementation MCSwitchCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor colorNamed:@"ngaBackgroundColor"];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


- (void) switchOn {
    [self.switchControl setOn:YES];
}


- (void) switchOff {
    [self.switchControl setOn:NO];
}


- (IBAction)switchChanged:(id)sender {
    [self.switchDelegate switchChanged:sender];
}


@end
