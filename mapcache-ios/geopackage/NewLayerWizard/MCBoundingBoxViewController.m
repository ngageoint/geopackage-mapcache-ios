//
//  MCBoundingBoxViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/2/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCBoundingBoxViewController.h"

@interface MCBoundingBoxViewController ()
@property (nonatomic) BOOL boundingBoxMode;
@property (nonatomic) BOOL drawing;
@property (nonatomic, strong) MKPolygon * boundingBox;
@property (nonatomic) CLLocationCoordinate2D boundingBoxStartCorner;
@property (nonatomic) CLLocationCoordinate2D boundingBoxEndCorner;
@property (nonatomic) enum GPKGSEditType editFeatureType;
@property (nonatomic, strong) GPKGMapShapePoints * editFeatureShape;
@property (nonatomic, strong) NSObject <GPKGShapePoints> * editFeatureShapePoints;
@property (nonatomic, strong) MKPolygon * editPolygon;
@property (nonatomic, strong) NSMutableArray * editPoints;
@property (nonatomic, strong) NSNumberFormatter *locationDecimalFormatter;
@end

@implementation MCBoundingBoxViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _mapView.delegate = self;
    
    _statusLabel.text = @"Tap the Draw tile bounds button and draw a box to set the area for your tile layer.";
    
    _boundingBoxMode = NO;
    [_cancelButton setHidden:YES];
    [_confirmButton setHidden:YES];
    
    [_mapView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget: self action:@selector(longPressGesture:)]];
    
    self.editFeatureType = GPKGS_ET_NONE;
    
    self.locationDecimalFormatter = [[NSNumberFormatter alloc] init];
    self.locationDecimalFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    self.locationDecimalFormatter.maximumFractionDigits = 4;
    
    self.boundingBoxStartCorner = kCLLocationCoordinate2DInvalid;
    self.boundingBoxEndCorner = kCLLocationCoordinate2DInvalid;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)boundingBoxButtonTapped:(id)sender {
    _boundingBoxMode = YES;
    
    [self animateButtonShowHide:_boundingBoxButton :YES];
    [self animateButtonShowHide:_cancelButton :NO];
    [self animateButtonShowHide:_confirmButton :NO];
    
    _statusLabel.text = @"Long press on the map to start drawing your bounding box.";
}


- (IBAction)cancelButtonTapped:(id)sender {
    _statusLabel.text = @"Tap the Draw tile bounds button and draw a box to set the area for your tile layer.";
    
    _boundingBoxMode = NO;
    [self animateButtonShowHide:_boundingBoxButton :NO];
    [self animateButtonShowHide:_cancelButton :YES];
    [self animateButtonShowHide:_confirmButton :YES];
    
    [_mapView removeOverlay:_boundingBox];
    _boundingBox = nil;
}


- (IBAction)confirmButtonTapped:(id)sender {
    
    NSDecimalNumber *minLat;
    NSDecimalNumber *maxLat;
    NSDecimalNumber *minLon;
    NSDecimalNumber *maxLon;
    
    
    if (_boundingBoxStartCorner.latitude < _boundingBoxEndCorner.latitude) {
        minLat = [[NSDecimalNumber alloc] initWithDouble: _boundingBoxStartCorner.latitude];
        maxLat = [[NSDecimalNumber alloc] initWithDouble: _boundingBoxEndCorner.latitude];
    } else {
        minLat = [[NSDecimalNumber alloc] initWithDouble: _boundingBoxEndCorner.latitude];
        maxLat = [[NSDecimalNumber alloc] initWithDouble: _boundingBoxStartCorner.latitude];
    }
    
    if (_boundingBoxStartCorner.longitude < _boundingBoxEndCorner.longitude) {
        minLon = [[NSDecimalNumber alloc] initWithDouble: _boundingBoxStartCorner.longitude];
        maxLon = [[NSDecimalNumber alloc] initWithDouble:_boundingBoxEndCorner.longitude];
    } else {
        minLon = [[NSDecimalNumber alloc] initWithDouble:_boundingBoxEndCorner.longitude];
        maxLon = [[NSDecimalNumber alloc] initWithDouble:_boundingBoxStartCorner.longitude];
    }
    
    GPKGBoundingBox *boundingBox = [[GPKGBoundingBox alloc] initWithMinLongitude:minLon  andMinLatitude:minLat andMaxLongitude:maxLon andMaxLatitude:maxLat];
    [_delegate boundingBoxCompletionHandler: boundingBox];
}


-(void) longPressGesture:(UILongPressGestureRecognizer *) longPressGestureRecognizer {
    NSLog(@"Getting a long press gesture.");
    
    CGPoint cgPoint = [longPressGestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D point = [self.mapView convertPoint:cgPoint toCoordinateFromView:self.mapView];
    
    if(self.boundingBoxMode){
        NSLog(@"Bounding Box mode");
        if(longPressGestureRecognizer.state == UIGestureRecognizerStateBegan){
            
            // Check to see if editing any of the bounding box corners
            if (self.boundingBox != nil && CLLocationCoordinate2DIsValid(self.boundingBoxEndCorner)) {
                
                double allowableScreenPercentage = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_TILES_LONG_CLICK_SCREEN_PERCENTAGE] intValue] / 100.0;
                if([self isWithinDistanceWithPoint:cgPoint andLocation:self.boundingBoxEndCorner andAllowableScreenPercentage:allowableScreenPercentage]){
                    [self setDrawing:true];
                }else if([self isWithinDistanceWithPoint:cgPoint andLocation:self.boundingBoxStartCorner andAllowableScreenPercentage:allowableScreenPercentage]){
                    CLLocationCoordinate2D temp = self.boundingBoxStartCorner;
                    self.boundingBoxStartCorner = self.boundingBoxEndCorner;
                    self.boundingBoxEndCorner = temp;
                    [self setDrawing:true];
                }else{
                    CLLocationCoordinate2D corner1 = CLLocationCoordinate2DMake(self.boundingBoxStartCorner.latitude, self.boundingBoxEndCorner.longitude);
                    CLLocationCoordinate2D corner2 = CLLocationCoordinate2DMake(self.boundingBoxEndCorner.latitude, self.boundingBoxStartCorner.longitude);
                    if([self isWithinDistanceWithPoint:cgPoint andLocation:corner1 andAllowableScreenPercentage:allowableScreenPercentage]){
                        self.boundingBoxStartCorner = corner2;
                        self.boundingBoxEndCorner = corner1;
                        [self setDrawing:true];
                    }else if([self isWithinDistanceWithPoint:cgPoint andLocation:corner2 andAllowableScreenPercentage:allowableScreenPercentage]){
                        self.boundingBoxStartCorner = corner1;
                        self.boundingBoxEndCorner = corner2;
                        [self setDrawing:true];
                    }
                }
            }
            
            // Start drawing a new polygon
            if(!self.drawing){
                if(self.boundingBox != nil){
                    [self.mapView removeOverlay:self.boundingBox];
                }
                self.boundingBoxStartCorner = point;
                self.boundingBoxEndCorner = point;
                CLLocationCoordinate2D * points = [self getPolygonPointsWithPoint1:self.boundingBoxStartCorner andPoint2:self.boundingBoxEndCorner];
                self.boundingBox = [MKPolygon polygonWithCoordinates:points count:4];
                
                [self.mapView addOverlay:self.boundingBox];
                [self setDrawing:true];
                //[self.boundingBoxClearButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_BOUNDING_BOX_CLEAR_ACTIVE_IMAGE] forState:UIControlStateNormal];
            }
            
        }else{
            switch(longPressGestureRecognizer.state){
                case UIGestureRecognizerStateChanged:
                case UIGestureRecognizerStateEnded:
                    if(self.boundingBoxMode){
                        if(self.drawing && self.boundingBox != nil){
                            self.boundingBoxEndCorner = point;
                            CLLocationCoordinate2D * points = [self getPolygonPointsWithPoint1:self.boundingBoxStartCorner andPoint2:self.boundingBoxEndCorner];
                            MKPolygon * newBoundingBox = [MKPolygon polygonWithCoordinates:points count:4];
                            [self.mapView removeOverlay:self.boundingBox];
                            [self.mapView addOverlay:newBoundingBox];
                            self.boundingBox = newBoundingBox;
                            
                            _statusLabel.text = @"You can long press on the corners of the bounding box and drag to adjust it.";
                        }
                        if(longPressGestureRecognizer.state == UIGestureRecognizerStateEnded){
                            [self setDrawing:false];
                        }
                    }
                    break;
                default:
                    break;
            }
        }
    } else if(self.editFeatureType != GPKGS_ET_NONE){
        
        if(longPressGestureRecognizer.state == UIGestureRecognizerStateBegan){
            if(self.editFeatureType == GPKGS_ET_EDIT_FEATURE){
                if(self.editFeatureShapePoints != nil){
                    GPKGMapPoint * mapPoint = [self addEditPoint:point];
                    [self.editFeatureShapePoints addNewPoint:mapPoint];
                    [self.editFeatureShape addPoint:mapPoint withShape:self.editFeatureShapePoints];
                    GPKGSMapPointData * data = [self getOrCreateDataWithMapPoint:mapPoint];
                    data.type = GPKGS_MPDT_EDIT_FEATURE_POINT;
                    [self setTitleWithGeometryType:self.editFeatureShape.shape.geometryType andMapPoint:mapPoint];
                    [self updateEditState:true]; // TODO figure out if I need all of this method
                }
            }else{
                GPKGMapPoint * mapPoint = [self addEditPoint:point];
                [self setTitleWithTitle:[GPKGSEditTypes pointName:self.editFeatureType] andMapPoint:mapPoint];
                [self updateEditState:true]; // TODO figure out if I need all of this method
            }
        }
    }
}


-(void) updateEditState: (BOOL) updateAcceptClear{
    BOOL accept = false;
    
    switch(self.editFeatureType){
            
        case GPKGS_ET_POLYGON:
            
            if([self.editPoints count] >= 3){
                accept = true;
                
                NSArray * points = [self getLocationPoints:self.editPoints];
                CLLocationCoordinate2D * locations = [GPKGMapShapeConverter getLocationCoordinatesFromLocations:points];
                
                MKPolygon * tempPolygon  = [MKPolygon polygonWithCoordinates:locations count:[points count] interiorPolygons:nil];
                if(self.editPolygon != nil){
                    [self.mapView removeOverlay:self.editPolygon];
                }
                self.editPolygon = tempPolygon;
                [self.mapView addOverlay:self.editPolygon];
            } else if(self.editPolygon != nil){
                [self.mapView removeOverlay:self.editPolygon];
                self.editPolygon = nil;
            }
            
            break;
        default:
            break;
    }
}


-(BOOL) isWithinDistanceWithPoint: (CGPoint) point andLocation: (CLLocationCoordinate2D) location andAllowableScreenPercentage: (double) allowableScreenPercentage{
    
    CGPoint locationPoint = [self.mapView convertCoordinate:location toPointToView:self.mapView];
    double distance = sqrt(pow(point.x - locationPoint.x, 2) + pow(point.y - locationPoint.y, 2));
    
    BOOL withinDistance = distance / MIN(self.mapView.frame.size.width, self.mapView.frame.size.height) <= allowableScreenPercentage;
    return withinDistance;
}


-(CLLocationCoordinate2D *) getPolygonPointsWithPoint1: (CLLocationCoordinate2D) point1 andPoint2: (CLLocationCoordinate2D) point2{
    CLLocationCoordinate2D *coordinates = calloc(4, sizeof(CLLocationCoordinate2D));
    coordinates[0] = CLLocationCoordinate2DMake(point1.latitude, point1.longitude);
    coordinates[1] = CLLocationCoordinate2DMake(point1.latitude, point2.longitude);
    coordinates[2] = CLLocationCoordinate2DMake(point2.latitude, point2.longitude);
    coordinates[3] = CLLocationCoordinate2DMake(point2.latitude, point1.longitude);
    return coordinates;
}


-(GPKGSMapPointData *) getOrCreateDataWithMapPoint: (GPKGMapPoint *) mapPoint{
    if(mapPoint.data == nil){
        mapPoint.data = [[GPKGSMapPointData alloc] init];
    }
    return (GPKGSMapPointData *) mapPoint.data;
}


-(void) setTitleWithGeometryType: (enum WKBGeometryType) type andMapPoint: (GPKGMapPoint *) mapPoint{
    NSString * title = nil;
    if(type != WKB_NONE){
        title = [WKBGeometryTypes name:type];
    }
    [self setTitleWithTitle:title andMapPoint:mapPoint];
}


-(void) setTitleWithTitle: (NSString *) title andMapPoint: (GPKGMapPoint *) mapPoint{
    
    NSString * locationTitle = [self buildLocationTitleWithMapPoint:mapPoint];
    
    if(title == nil){
        [mapPoint setTitle:locationTitle];
    }else{
        [mapPoint setTitle:title];
        [mapPoint setSubtitle:locationTitle];
    }
}


-(NSString *) buildLocationTitleWithMapPoint: (GPKGMapPoint *) mapPoint{
    
    CLLocationCoordinate2D coordinate = mapPoint.coordinate;
    
    NSString *lat = [self.locationDecimalFormatter stringFromNumber:[NSNumber numberWithDouble:coordinate.latitude]];
    NSString *lon = [self.locationDecimalFormatter stringFromNumber:[NSNumber numberWithDouble:coordinate.longitude]];
    
    NSString * title = [NSString stringWithFormat:@"(lat=%@, lon=%@)", lat, lon];
    
    return title;
}


-(GPKGMapPoint *) addEditPoint: (CLLocationCoordinate2D) point{
    GPKGMapPoint * mapPoint = [[GPKGMapPoint alloc] initWithLocation:point];
    mapPoint.options.draggable = true;
    
    switch(self.editFeatureType){
        case GPKGS_ET_POINT:
            [mapPoint.options setPinTintColor:[UIColor redColor]];
            break;
        case GPKGS_ET_LINESTRING:
        case GPKGS_ET_POLYGON:
            [mapPoint.options setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_POINT_IMAGE]];
            [mapPoint.options setPinTintColor:[UIColor greenColor]];
            break;
        case GPKGS_ET_POLYGON_HOLE:
            [mapPoint.options setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_HOLE_POINT_IMAGE]];
            break;
        case GPKGS_ET_EDIT_FEATURE:
            
            break;
        default:
            break;
    }
    [self.mapView addAnnotation:mapPoint];
    return mapPoint;
}


-(NSArray *) getLocationPoints: (NSArray *) pointArray{
    NSMutableArray * points = [[NSMutableArray alloc] init];
    for(GPKGMapPoint * editPoint in pointArray){
        CLLocation * location = [[CLLocation alloc] initWithLatitude:editPoint.coordinate.latitude longitude:editPoint.coordinate.longitude];
        [points addObject:location];
    }
    return points;
}



- (void) animateButtonShowHide:(UIButton *) button :(BOOL)isHidden {
    [UIView transitionWithView:button
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        button.hidden = isHidden;
                    }
                    completion:NULL];
}


#pragma mark- MKMapView delegate methods
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id)overlay {
    MKOverlayRenderer * rendered = nil;
    if ([overlay isKindOfClass:[MKPolygon class]]) {
        MKPolygonRenderer * polygonRenderer = [[MKPolygonRenderer alloc] initWithPolygon:overlay];
        if(self.drawing || (self.boundingBox != nil && self.boundingBox == overlay)){
            polygonRenderer.strokeColor = [GPKGSColorUtil getPolygonStrokeColor];
            polygonRenderer.lineWidth = 2.0;
            polygonRenderer.fillColor = [GPKGSColorUtil getPolygonFillColor];
        } else {
            polygonRenderer.strokeColor = [GPKGSColorUtil getPolygonStrokeColor];
            polygonRenderer.lineWidth = 2.0;
            polygonRenderer.fillColor = [GPKGSColorUtil getPolygonFillColor];
        }
        rendered = polygonRenderer;
    }
    return rendered;
}



@end
