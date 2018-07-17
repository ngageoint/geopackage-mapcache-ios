//
//  GPKGSHeaderCellTableViewCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/17/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "GPKGSConstants.h"
#import "MCHeaderCell.h"

@implementation MCHeaderCell

- (void)awakeFromNib {
    [super awakeFromNib];
    _nameLabel.numberOfLines = 0;
    [self setBackgroundColor:[UIColor clearColor]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    self.mapView.zoomEnabled = false;
    self.mapView.scrollEnabled = false;
    self.mapView.userInteractionEnabled = false;
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}

@end
