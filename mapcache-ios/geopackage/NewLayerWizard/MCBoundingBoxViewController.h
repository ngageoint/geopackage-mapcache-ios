//
//  MCBoundingBoxViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/2/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGSEditTypes.h"
#import "GPKGSMapPointData.h"
#import "GPKGMapShapePoints.h"
#import "GPKGMapPoint.h"
#import "GPKGMapShapeConverter.h"
#import "GPKGSColorUtil.h";

@interface MCBoundingBoxViewController : UIViewController <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *boundingBoxButton;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *confirmButton;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@end
