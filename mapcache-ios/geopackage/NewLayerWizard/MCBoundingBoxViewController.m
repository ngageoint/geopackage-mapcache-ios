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
@property (nonatomic) double minLat;
@property (nonatomic) double maxLat;
@property (nonatomic) double minLon;
@property (nonatomic) double maxLon;
@property (nonatomic) enum GPKGSEditType editFeatureType;
@property (nonatomic, strong) GPKGMapShapePoints * editFeatureShape;
@property (nonatomic, strong) NSObject <GPKGShapePoints> * editFeatureShapePoints;
@property (nonatomic, strong) MKPolygon * editPolygon;
@property (nonatomic, strong) NSMutableArray * editPoints;
@property (nonatomic, strong) NSNumberFormatter *locationDecimalFormatter;
@property (nonatomic, strong) UIBarButtonItem *nextButton;
@end

@implementation MCBoundingBoxViewController

- (void)viewWillAppear:(BOOL)animated {
    [UILabel appearanceWhenContainedInInstancesOfClasses:@[[UINavigationBar class]]].textColor = [UIColor whiteColor];
    [[UINavigationBar appearance] setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]}];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    
    _mapView.delegate = self;
    _boundingBoxMode = YES;
    
    self.navigationItem.title = @"Select an area";
    self.navigationItem.prompt = @"Long press on the map to start drawing your bounding box.";
    
    [_editBoundingBoxButton setTitle:@"Enter Bounding Box" forState:UIControlStateNormal];
    [_editBoundingBoxButton.titleLabel setTextAlignment:NSTextAlignmentCenter];
    
    [_mapView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget: self action:@selector(longPressGesture:)]];
    
    self.editFeatureType = GPKGS_ET_NONE;
    
    self.locationDecimalFormatter = [[NSNumberFormatter alloc] init];
    self.locationDecimalFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    self.locationDecimalFormatter.maximumFractionDigits = 4;
    
    self.boundingBoxStartCorner = kCLLocationCoordinate2DInvalid;
    self.boundingBoxEndCorner = kCLLocationCoordinate2DInvalid;
    _minLat = 0.0;
    _minLon = 0.0;
    _maxLat = 0.0;
    _maxLon = 0.0;
    
    _nextButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStylePlain target:self action:@selector(nextButtonTapped)];
    _nextButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = _nextButton;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)editCoordinatesButtonTapped:(id)sender {
    [_delegate showManualBoundingBoxViewWithMinLat: _minLat andMaxLat:_maxLat andMinLon:_minLon andMaxLon:_maxLon];
}


- (void) nextButtonTapped {
    
    GPKGBoundingBox *boundingBox = [[GPKGBoundingBox alloc] initWithMinLongitude:[[NSDecimalNumber alloc] initWithDouble:_minLon]
                                                                  andMinLatitude:[[NSDecimalNumber alloc] initWithDouble:_minLat]
                                                                 andMaxLongitude:[[NSDecimalNumber alloc] initWithDouble:_maxLon]
                                                                  andMaxLatitude:[[NSDecimalNumber alloc] initWithDouble:_maxLat]];
    [_delegate boundingBoxCompletionHandler: boundingBox];
}


-(void) longPressGesture:(UILongPressGestureRecognizer *) longPressGestureRecognizer {
    NSLog(@"Getting a long press gesture.");
    
    CGPoint cgPoint = [longPressGestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D point = [self.mapView convertPoint:cgPoint toCoordinateFromView:self.mapView];
    
    if(self.boundingBoxMode){
        NSLog(@"Bounding Box mode");
        if(longPressGestureRecognizer.state == UIGestureRecognizerStateBegan){
            [_editBoundingBoxButton setTitle:@"Edit Bounding Box" forState:UIControlStateNormal];
            
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
                            _nextButton.enabled = YES;
                            self.navigationItem.prompt = @"You can drag the corners of the bounding box to adjust it.";
                            
                            if (_boundingBoxStartCorner.latitude > _boundingBoxEndCorner.latitude) {
                                _minLat = _boundingBoxEndCorner.latitude;
                                _maxLat = _boundingBoxStartCorner.latitude;
                                
                                _upperRightLatitudeLabel.text = [NSString stringWithFormat:@"Lat: %.2f", self.boundingBoxStartCorner.latitude];
                                _lowerLeftLatitudeLabel.text = [NSString stringWithFormat:@"Lat: %.2f", self.boundingBoxEndCorner.latitude];
                            } else {
                                _minLat = _boundingBoxStartCorner.latitude;
                                _maxLat = _boundingBoxEndCorner.latitude;
                                
                                _upperRightLatitudeLabel.text = [NSString stringWithFormat:@"Lat: %.2f", self.boundingBoxEndCorner.latitude];
                                _lowerLeftLatitudeLabel.text = [NSString stringWithFormat:@"Lat: %.2f", self.boundingBoxStartCorner.latitude];
                            }
                            
                            if (_boundingBoxStartCorner.longitude < _boundingBoxEndCorner.longitude) {
                                _minLon = _boundingBoxStartCorner.longitude;
                                _maxLon = _boundingBoxEndCorner.longitude;
                                
                                _lowerLeftLongitudeLabel.text = [NSString stringWithFormat:@"Lon: %.2f", self.boundingBoxStartCorner.longitude];
                                _upperRightLongitudeLabel.text = [NSString stringWithFormat:@"Lon: %.2f", self.boundingBoxEndCorner.longitude];
                            } else {
                                _minLon = _boundingBoxEndCorner.longitude;
                                _maxLon = _boundingBoxStartCorner.longitude;
                                
                                _lowerLeftLongitudeLabel.text = [NSString stringWithFormat:@"Lon: %.2f", self.boundingBoxEndCorner.longitude];
                                _upperRightLongitudeLabel.text = [NSString stringWithFormat:@"Lon: %.2f", self.boundingBoxStartCorner.longitude];
                            }
                            
                            
                            [self animateShowHide:_lowerLeftLabel :NO];
                            [self animateShowHide:_upperRightLabel :NO];
                            [self animateShowHide:_lowerLeftLatitudeLabel :NO];
                            [self animateShowHide:_lowerLeftLongitudeLabel :NO];
                            [self animateShowHide:_upperRightLatitudeLabel :NO];
                            [self animateShowHide:_upperRightLongitudeLabel :NO];
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


- (void) setBoundingBoxWithLowerLeftLat:(double)lowerLeftLat andLowerLeftLon:(double)lowerLeftLon andUpperRightLat:(double) upperRightLat andUpperRightLon:(double)upperRightLon {
    _boundingBoxStartCorner = CLLocationCoordinate2DMake(lowerLeftLat, lowerLeftLon);
    _boundingBoxEndCorner = CLLocationCoordinate2DMake(upperRightLat, upperRightLon);
    
    CLLocationCoordinate2D * points = [self getPolygonPointsWithPoint1:_boundingBoxStartCorner andPoint2: _boundingBoxEndCorner];
    MKPolygon * newBoundingBox = [MKPolygon polygonWithCoordinates:points count:4];
    [self.mapView removeOverlay:self.boundingBox];
    [self.mapView addOverlay:newBoundingBox];
    self.boundingBox = newBoundingBox;
    
    _minLat = lowerLeftLat;
    _minLon = lowerLeftLon;
    _maxLat = upperRightLat;
    _maxLon = upperRightLon;
}


-(void) setTitleWithGeometryType: (enum SFGeometryType) type andMapPoint: (GPKGMapPoint *) mapPoint{
    NSString * title = nil;
    if(type != SF_NONE){
        title = [SFGeometryTypes name:type];
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



- (void) animateShowHide:(UIView *) view :(BOOL)isHidden {
    [UIView transitionWithView:view
                      duration:0.3
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                        view.hidden = isHidden;
                    }
                    completion:NULL];
}


#pragma mark- MKMapView delegate methods
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id)overlay {
    MKOverlayRenderer * rendered = nil;
    if ([overlay isKindOfClass:[MKPolygon class]]) {
        MKPolygonRenderer * polygonRenderer = [[MKPolygonRenderer alloc] initWithPolygon:overlay];
        if(self.drawing || (self.boundingBox != nil && self.boundingBox == overlay)){
            polygonRenderer.strokeColor = [MCColorUtil getPolygonStrokeColor];
            polygonRenderer.lineWidth = 2.0;
            polygonRenderer.fillColor = [MCColorUtil getPolygonFillColor];
        } else {
            polygonRenderer.strokeColor = [MCColorUtil getPolygonStrokeColor];
            polygonRenderer.lineWidth = 2.0;
            polygonRenderer.fillColor = [MCColorUtil getPolygonFillColor];
        }
        rendered = polygonRenderer;
    }
    return rendered;
}



@end
