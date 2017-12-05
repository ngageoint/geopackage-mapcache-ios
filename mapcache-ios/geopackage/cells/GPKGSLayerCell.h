//
//  GPKGSLayerCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/21/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GPKGSLayerCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIImageView *layerTypeImage;
@property (weak, nonatomic) IBOutlet UILabel *layerNameLabel;
@end
