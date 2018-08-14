//
//  GPKGSHeaderCellTableViewCell.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/17/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "GPKGSConstants.h"
#import "MCHeaderCell.h"

@implementation MCHeaderCell

- (void)awakeFromNib {
    [super awakeFromNib];
    _nameLabel.numberOfLines = 0;
    [self setBackgroundColor:[UIColor clearColor]];
    [self setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    //self.mapView.zoomEnabled = false;
    //self.mapView.scrollEnabled = false;
    //self.mapView.userInteractionEnabled = false;
    self.mapView.delegate = self;
}


- (void)willMoveToSuperview:(UIView *)newSuperview {
    //[super willMoveToSuperview:newSuperview];
    
    if (self.tileOverlay != nil) {
        //dispatch_sync(dispatch_get_main_queue(), ^{
            [self.mapView addOverlay:self.tileOverlay];
        //});
    } else if (self.featureDao != nil) {
        GPKGResultSet *featureResultSet = [self.featureDao queryForAll];
        GPKGMapShapeConverter *converter = [[GPKGMapShapeConverter alloc] initWithProjection: self.featureDao.projection];
        
        while ([featureResultSet moveToNext]) {
            GPKGFeatureRow *featureRow = [self.featureDao getFeatureRow:featureResultSet];
            GPKGGeometryData *geometryData = [featureRow getGeometry];
            GPKGMapShape *shape = [converter toShapeWithGeometry:geometryData.geometry];
            
            //dispatch_sync(dispatch_get_main_queue(), ^{
                [GPKGMapShapeConverter addMapShape:shape toMapView:self.mapView];
            //});
        }
    }
}


- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
}


- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKOverlayRenderer *renderer = [[MKOverlayRenderer alloc] init];
    
    if ([overlay isKindOfClass:[MKPolygon class]]) {
        MKPolygonRenderer *polygonRenderer = [[MKPolygonRenderer alloc] initWithPolygon:(MKPolygon *)overlay];
        polygonRenderer.fillColor = [[UIColor alloc] initWithRed:0.0 green:1.0 blue:0.6 alpha:0.5];
        polygonRenderer.lineWidth = 1;
        polygonRenderer.strokeColor = UIColor.blackColor;
        renderer = polygonRenderer;
    } else if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        renderer = [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    }
    
    return renderer;
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKAnnotationView *annotationView = [mapView dequeueReusableAnnotationViewWithIdentifier:@"annotation"];
    
    
    
    return annotationView;
}

@end
