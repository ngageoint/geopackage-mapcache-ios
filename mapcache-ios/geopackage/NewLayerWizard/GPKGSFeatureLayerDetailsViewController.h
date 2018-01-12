//
//  GPKGSFeatureLayerDetailsViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/12/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "GPKGSDesctiptionCell.h"
#import "GPKGSSectionTitleCell.h"
#import "GPKGSFieldWithTitleCell.h"


@interface GPKGSFeatureLayerDetailsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource>

@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@end
