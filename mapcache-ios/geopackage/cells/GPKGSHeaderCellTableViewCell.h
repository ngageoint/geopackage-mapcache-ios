//
//  GPKGSHeaderCellTableViewCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/17/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GPKGSHeaderCellTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *tileLayerCount;
@property (weak, nonatomic) IBOutlet UILabel *featureLayerCount;

@end
