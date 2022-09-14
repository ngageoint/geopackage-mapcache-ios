//
//  MCGeoPackageButtonsCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 7/9/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCGeoPackageOperationsCell.h"

@implementation MCGeoPackageOperationsCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundColor = [UIColor clearColor];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (IBAction)renameButtonTapped:(id)sender {
    [_delegate renameGeoPackage];
}


- (IBAction)shareButtonTapped:(id)sender {
    [_delegate shareGeoPackage];
}


- (IBAction)duplicateButtonTapped:(id)sender {
    [_delegate copyGeoPackage];
}


- (IBAction)deleteButtonTapped:(id)sender {
    [_delegate deleteGeoPackage];
}

@end
