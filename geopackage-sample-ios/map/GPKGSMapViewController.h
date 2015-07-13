//
//  GPKGSMapViewController.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/13/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSMapView.h"

@interface GPKGSMapViewController : UIViewController <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet GPKGSMapView *mapView;

@end
