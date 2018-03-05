//
//  MCBoundingBoxViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/2/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <QuartzCore/QuartzCore.h>
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
- (void) showManualBoundingBoxViewWithMinLat:(double)minLat andMaxLat:(double)maxLat andMinLon:(double)minLon andMaxLon:(double)maxLon;
- (void) boundingBoxCompletionHandler:(GPKGBoundingBox *) boundingBox;
@end


@interface MCBoundingBoxViewController : UIViewController <MKMapViewDelegate>
@property (weak, nonatomic) IBOutlet UIButton *editBoundingBoxButton;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (weak, nonatomic) IBOutlet UILabel *lowerLeftLatitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *lowerLeftLongitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *upperRightLatitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *upperRightLongitudeLabel;
@property (weak, nonatomic) IBOutlet UILabel *lowerLeftLabel;
@property (weak, nonatomic) IBOutlet UILabel *upperRightLabel;
@property (weak, nonatomic) id<MCTileLayerBoundingBoxDelegate> delegate;
- (void) setBoundingBoxWithLowerLeftLat:(double)lowerLeftLat andLowerLeftLon:(double)lowerLeftLon andUpperRightLat:(double) upperRightLat andUpperRightLon:(double)upperRightLon;
@end
