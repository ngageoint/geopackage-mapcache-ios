//
//  MCBoundingBoxViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/2/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface MCBoundingBoxViewController : UIViewController
@property (weak, nonatomic) IBOutlet UIButton *boundingBoxButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@end
