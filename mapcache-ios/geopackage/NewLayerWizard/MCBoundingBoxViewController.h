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
#import "GPKGSColorUtil.h"
#import "GPKGBoundingBox.h"

@protocol MCTileLayerBoundingBoxDelegate
- (void) showManualBoundingBoxView;
- (void) boundingBoxCompletionHandler:(GPKGBoundingBox *) boundingBox;
@end


@interface MCBoundingBoxViewController : UIViewController <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *editBoundingBoxButton;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *upperLeftValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *lowerRightValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *upperLeftLabel;
@property (weak, nonatomic) IBOutlet UILabel *lowerRightLabel;
@property (weak, nonatomic) id<MCTileLayerBoundingBoxDelegate> delegate;
@end
