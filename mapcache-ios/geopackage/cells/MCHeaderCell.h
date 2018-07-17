//
//  GPKGSHeaderCellTableViewCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/17/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MCHeaderCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabelOne;
@property (weak, nonatomic) IBOutlet UILabel *detailLabelTwo;
@property (weak, nonatomic) IBOutlet UILabel *detailLabelThree;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@end
