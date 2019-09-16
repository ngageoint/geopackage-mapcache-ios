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


- (void)animateSwipeHint {  
    [UIView animateWithDuration:0.45 delay:0.3 options:UIViewAnimationOptionCurveLinear animations:^{
        self.contentView.transform = CGAffineTransformMakeTranslation(24, 0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.contentView.transform = CGAffineTransformMakeTranslation(0, 0);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.45 delay:0.3 options:UIViewAnimationOptionCurveLinear animations:^{
                self.contentView.transform = CGAffineTransformMakeTranslation(24, 0);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                    self.contentView.transform = CGAffineTransformMakeTranslation(0, 0);
                } completion:nil];
            }];
        }];
    }];
}

@end
