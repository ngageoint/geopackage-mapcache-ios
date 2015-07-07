//
//  GPKGSDatabaseCell.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSDatabaseOptionsButton.h"

@interface GPKGSDatabaseCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *database;
@property (weak, nonatomic) IBOutlet UIImageView *expandImage;
@property (weak, nonatomic) IBOutlet GPKGSDatabaseOptionsButton *optionsButton;

@end
