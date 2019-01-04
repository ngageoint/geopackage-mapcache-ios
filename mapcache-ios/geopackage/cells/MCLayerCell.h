//
//  GPKGSLayerCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/21/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "GPKGSTable.h"
#import <UIKit/UIKit.h>


@interface MCLayerCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *activeIndicator;
@property (weak, nonatomic) IBOutlet UIImageView *layerTypeImage;
@property (weak, nonatomic) IBOutlet UILabel *layerNameLabel;
@property (nonatomic, strong) GPKGSTable *table;
- (void)activeIndicatorOn;
- (void)activeIndicatorOff;
- (void)toggleActiveIndicator;
@end
