//
//  MCGeoPackageCell.m
//  MapDrawer
//
//  Created by Tyler Burgett on 8/17/18.
//  Copyright © 2018 GeoPackage. All rights reserved.
//

#import "MCGeoPackageCell.h"

@implementation MCGeoPackageCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.visibilityStatusIndicator.image = [UIImage imageNamed:@"allLayersOn"];
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}


- (void)activeLayersIndicatorOn {
    [self.visibilityStatusIndicator setHidden:NO];
}


- (void)activeLayersIndicatorOff {
    [self.visibilityStatusIndicator setHidden:YES];
}


- (void)toggleActiveIndicator {
    if (self.visibilityStatusIndicator.isHidden) {
        [self.visibilityStatusIndicator setHidden:NO];
    } else {
        [self.visibilityStatusIndicator setHidden:YES];
    }
}

@end
