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
#import "MCDatabases.h"
#import "MCDatabase.h"
#import "GPKGGeoPackageManager.h"
#import "GPKGGeoPackageFactory.h"
#import "MCUtils.h"
#import "GPKGUtils.h"
#import "GPKGMapUtils.h"
#import "GPKGTileBoundingBoxUtils.h"
#import "GPKGTileTableScaling.h"
#import "GPKGMultipleFeatureIndexResults.h"
#import "GPKGFeatureShapes.h"
#import "SFPProjectionFactory.h"
#import "SFGeometryEnvelopeBuilder.h"
#import "MCTileHelper.h"
#import "MCFeatureHelper.h"
#import "GPKGBoundingBox.h"
#import "GPKGMapShapeTypes.h"


@protocol MCMapActionDelegate <NSObject>
- (void)showMapInfoDrawer;
- (void)showDrawingTools;
- (void)updateDrawingStatus;
- (void)showDetailsForAnnotation:(GPKGMapPoint *)mapPoint;
@end


@interface MCMapViewController : UIViewController <MKMapViewDelegate, MCTileHelperDelegate, MCFeatureHelperDelegate, MCMapSettingsDelegate, CLLocationManagerDelegate>
@property (nonatomic, weak) IBOutlet MKMapView *mapView;
@property (nonatomic, weak) IBOutlet UIButton *infoButton;
@property (nonatomic, weak) IBOutlet UIButton *locationButton;
@property (weak, nonatomic) IBOutlet UIButton *zoomIndicatorButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *zoomIndicatorButtonWidth;
@property (nonatomic, strong) id<MCMapActionDelegate> mapActionDelegate;
@property (nonatomic) BOOL drawing;
@property (nonatomic, strong) NSMutableArray *tempMapPoints;

- (int)updateInBackgroundWithZoom: (BOOL) zoom;
-(int) updateInBackgroundWithZoom: (BOOL) zoom andFilter: (BOOL) filter;
- (void)zoomToPointWithOffset:(CLLocationCoordinate2D) point;
- (CLLocationCoordinate2D) convertPointToCoordinate:(CGPoint) point;
- (void)toggleMapControls;
- (void)clearTempPoints;
- (void) removeMapPoint:(GPKGMapPoint *) mapPoint;
@end
