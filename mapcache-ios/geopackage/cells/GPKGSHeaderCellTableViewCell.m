//
//  GPKGSHeaderCellTableViewCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/17/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "GPKGSConstants.h"
#import "GPKGSHeaderCellTableViewCell.h"

@implementation GPKGSHeaderCellTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    _nameLabel.numberOfLines = 0;
    [self setBackgroundColor:[UIColor clearColor]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}



- (IBAction)deleteButtonTapped:(id)sender {
    [_delegate deleteGeoPackage];
}


- (IBAction)shareButtonTapped:(id)sender {
    [_delegate shareGeoPackage];
}


- (IBAction)renameButtonTapped:(id)sender {
    [_delegate renameGeoPackage];
}
@end
