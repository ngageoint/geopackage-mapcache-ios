//
//  MCMapViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 8/27/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "NGADrawerCoordinator.h"


@interface MCMapViewController : UIViewController
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@end
