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
    
    // iOS 13 dark mode support
    if ([UIColor respondsToSelector:@selector(systemBackgroundColor)]) {
        self.contentView.backgroundColor = [UIColor systemBackgroundColor];
    }
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


- (void)setContentWithDatabase: (MCDatabase *) database {
    self.database = database;
    [self.geoPackageNameLabel setText:database.name];
    
    if ([database getFeatures].count == 1) {
        [self.featureLayerDetailsLabel setText: [NSString stringWithFormat:@"%ld Feature layer", (long)[database getFeatures].count]];
     } else {
         [self.featureLayerDetailsLabel setText: [NSString stringWithFormat:@"%ld Feature layers", (long)[database getFeatures].count]];
     }
     
     if ([database getTileCount] == 1) {
         [self.tileLayerDetailsLabel setText: [NSString stringWithFormat:@"%ld Tile layer", (long)[database getTileCount]]];
     } else {
         [self.tileLayerDetailsLabel setText: [NSString stringWithFormat:@"%ld Tile layers", (long)[database getTileCount]]];
     }
}


- (void)setGeoPackageName:(NSString *) name {
    [self.geoPackageNameLabel setText:name];
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
    [UIView animateWithDuration:0.65 delay:0.3 options:UIViewAnimationOptionCurveLinear animations:^{
        self.contentView.transform = CGAffineTransformMakeTranslation(16, 0);
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
            self.contentView.transform = CGAffineTransformMakeTranslation(0, 0);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.65 delay:0.3 options:UIViewAnimationOptionCurveLinear animations:^{
                self.contentView.transform = CGAffineTransformMakeTranslation(16, 0);
            } completion:^(BOOL finished) {
                [UIView animateWithDuration:0.1 delay:0.0 options:UIViewAnimationOptionCurveLinear animations:^{
                    self.contentView.transform = CGAffineTransformMakeTranslation(0, 0);
                } completion:nil];
            }];
        }];
    }];
}

@end
