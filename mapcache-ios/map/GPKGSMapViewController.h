//
//  GPKGSMapViewController.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/13/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSMapView.h"
#import "GPKGSDownloadTilesViewController.h"

@interface GPKGSMapViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate, GPKGSDownloadTilesDelegate>

@property (weak, nonatomic) IBOutlet GPKGSMapView *mapView;
@property (weak, nonatomic) IBOutlet UIButton *boundingBoxButton;
@property (weak, nonatomic) IBOutlet UIButton *featuresButton;
@property (weak, nonatomic) IBOutlet UIButton *downloadTilesButton;
@property (weak, nonatomic) IBOutlet UIButton *featureTilesButton;
@property (weak, nonatomic) IBOutlet UIButton *boundingBoxClearButton;

@end
