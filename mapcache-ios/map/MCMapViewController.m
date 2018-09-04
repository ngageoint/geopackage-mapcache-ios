//
//  MCMapViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 8/27/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCMapViewController.h"

@interface MCMapViewController ()
@property (strong, nonatomic) NSMutableArray *childCoordinators;
@end


@implementation MCMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _childCoordinators = [[NSMutableArray alloc] init];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) addBottomSheetView {
    NGADrawerCoordinator *drawerCoordinator = [[NGADrawerCoordinator alloc] init];
    [drawerCoordinator start];
    [_childCoordinators addObject: drawerCoordinator];
}


// TODO: update code from the old header view to work with new map
//- (void)willMoveToSuperview:(UIView *)newSuperview {
//    if (self.tileOverlay != nil) {
//        //dispatch_sync(dispatch_get_main_queue(), ^{
//        [self.mapView addOverlay:self.tileOverlay];
//        //});
//    } else if (self.featureDao != nil) {
//        GPKGResultSet *featureResultSet = [self.featureDao queryForAll];
//        GPKGMapShapeConverter *converter = [[GPKGMapShapeConverter alloc] initWithProjection: self.featureDao.projection];
//
//        while ([featureResultSet moveToNext]) {
//            GPKGFeatureRow *featureRow = [self.featureDao getFeatureRow:featureResultSet];
//            GPKGGeometryData *geometryData = [featureRow getGeometry];
//            GPKGMapShape *shape = [converter toShapeWithGeometry:geometryData.geometry];
//
//            //dispatch_sync(dispatch_get_main_queue(), ^{
//            [GPKGMapShapeConverter addMapShape:shape toMapView:self.mapView];
//            //});
//        }
//    }
//}
//
//- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
//    MKOverlayRenderer *renderer = [[MKOverlayRenderer alloc] init];
//
//    if ([overlay isKindOfClass:[MKPolygon class]]) {
//        MKPolygonRenderer *polygonRenderer = [[MKPolygonRenderer alloc] initWithPolygon:(MKPolygon *)overlay];
//        polygonRenderer.fillColor = [[UIColor alloc] initWithRed:0.0 green:1.0 blue:0.6 alpha:0.5];
//        polygonRenderer.lineWidth = 1;
//        polygonRenderer.strokeColor = UIColor.blackColor;
//        renderer = polygonRenderer;
//    } else if ([overlay isKindOfClass:[MKTileOverlay class]]) {
//        renderer = [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
//    }
//
//    return renderer;
//}
//
//
//- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
//    MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"annotation"];
//
//
//
//    return annotationView;
//}

@end
