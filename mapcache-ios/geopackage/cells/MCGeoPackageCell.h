//
//  MCGeoPackageCell.h
//  MapDrawer
//
//  Created by Tyler Burgett on 8/17/18.
//  Copyright © 2018 GeoPackage. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MCGeoPackageCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *visibilityStatusIndicator;
@property (weak, nonatomic) IBOutlet UILabel *geoPackageNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *tileLayerDetailsLabel;
@property (weak, nonatomic) IBOutlet UILabel *featureLayerDetailsLabel;
- (void)activeLayersIndicatorOn;
@end
