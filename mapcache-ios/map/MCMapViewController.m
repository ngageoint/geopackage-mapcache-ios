//
//  MCMapViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 8/27/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCMapViewController.h"

@interface MCMapViewController ()
@property (nonatomic, strong) NSMutableArray *childCoordinators;
@property (nonatomic, strong) GPKGSDatabases *active;
@property (nonatomic, strong) NSUserDefaults *settings;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) NSMutableDictionary *geoPackages;
@property (nonatomic, strong) MCTileHelper *tileHelper;
@property (nonatomic, strong) MCFeatureHelper *featureHelper;
@property (nonatomic, strong) NSMutableDictionary *featureDaos;
@property (nonatomic, strong) GPKGBoundingBox *featuresBoundingBox;
@property (nonatomic, strong) GPKGBoundingBox *tilesBoundingBox;
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic) BOOL showingUserLocation;
@property (nonatomic) BOOL featureOverlayTiles;
@property (atomic) int updateCountId;
@property (atomic) int featureUpdateCountId;
@property (nonatomic, strong) GPKGFeatureShapes *featureShapes;
@property (nonatomic) BOOL needsInitialZoom;
@property (nonatomic, strong) UIColor *boundingBoxColor;
@property (nonatomic) double boundingBoxLineWidth;
@property (nonatomic, strong) UIColor *boundingBoxFillColor;
@property (nonatomic, strong) UIColor *defaultPolylineColor;
@property (nonatomic) double defaultPolylineLineWidth;
@property (nonatomic, strong) UIColor *defaultPolygonColor;
@property (nonatomic) double defaultPolygonLineWidth;
@property (nonatomic, strong) UIColor *defaultPolygonFillColor;
@property (nonatomic, strong) UIColor *editPolylineColor;
@property (nonatomic) double editPolylineLineWidth;
@property (nonatomic, strong) UIColor *editPolygonColor;
@property (nonatomic) double editPolygonLineWidth;
@property (nonatomic, strong) UIColor *editPolygonFillColor;
@property (nonatomic, strong) UIColor *drawPolylineColor;
@property (nonatomic) double drawPolylineLineWidth;
@property (nonatomic, strong) UIColor *drawPolygonColor;
@property (nonatomic) double drawPolygonLineWidth;
@property (nonatomic, strong) UIColor *drawPolygonFillColor;
@property (nonatomic, strong) NSNumberFormatter *locationDecimalFormatter;
@property (nonatomic) BOOL boundingBoxMode;
@property (nonatomic) BOOL drawing;
@property (nonatomic, strong) GPKGPolygon *boundingBox;
@property (nonatomic) CLLocationCoordinate2D boundingBoxStartCorner;
@property (nonatomic) CLLocationCoordinate2D boundingBoxEndCorner;
@property (nonatomic) double minLat;
@property (nonatomic) double maxLat;
@property (nonatomic) double minLon;
@property (nonatomic) double maxLon;
@property (nonatomic) BOOL settingsDrawerVisible;
@property (nonatomic) int currentZoom;
@end


@implementation MCMapViewController

static NSString *mapPointImageReuseIdentifier = @"mapPointImageReuseIdentifier";
static NSString *mapPointPinReuseIdentifier = @"mapPointPinReuseIdentifier";

- (void)viewDidLoad {
    [super viewDidLoad];
    _childCoordinators = [[NSMutableArray alloc] init];
    
    self.mapView.delegate = self;
    self.mapView.showsCompass = NO;
    [self setupColors];
    self.settings = [NSUserDefaults standardUserDefaults];
    self.geoPackages = [[NSMutableDictionary alloc] init];
    self.featureShapes = [[GPKGFeatureShapes alloc] init];
    self.featureDaos = [[NSMutableDictionary alloc] init];
    self.manager = [GPKGGeoPackageFactory getManager];
    self.active = [GPKGSDatabases getInstance];
    self.needsInitialZoom = true;
    self.updateCountId = 0;
    self.featureUpdateCountId = 0;
    [self.active setModified:YES];
    self.tileHelper = [[MCTileHelper alloc] initWithTileHelperDelegate:self];
    self.featureHelper = [[MCFeatureHelper alloc] initWithFeatureHelperDelegate:self];
    
    self.locationDecimalFormatter = [[NSNumberFormatter alloc] init];
    self.locationDecimalFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    self.locationDecimalFormatter.maximumFractionDigits = 4;
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.showingUserLocation = NO;
    self.settingsDrawerVisible = NO;
    self.currentZoom = -1;
    
    [self.view setNeedsLayout];
    
    self.boundingBoxMode = NO;
    [_mapView addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget: self action:@selector(longPressGesture:)]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(enableBoundingBoxMode) name:@"drawBoundingBox" object:nil];
    
    NSString *mapType = [self.settings stringForKey:GPKGS_PROP_MAP_TYPE];
    if (mapType == nil || [mapType isEqualToString:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_STANDARD]]) {
        [self.mapView setMapType:MKMapTypeStandard];
    } else if ([mapType isEqualToString:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_SATELLITE]]) {
        [self.mapView setMapType:MKMapTypeSatellite];
    } else {
        [self.mapView setMapType:MKMapTypeHybrid];
    }
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    if (self.active.modified) {
        [self.active setModified:NO];
        [self updateInBackgroundWithZoom:YES];
    }
}


- (void)layoutSubviews {
    CAShapeLayer * topCornersMaskLayer = [CAShapeLayer layer];
    topCornersMaskLayer.path = [UIBezierPath bezierPathWithRoundedRect: self.infoButton.bounds byRoundingCorners: UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii: (CGSize){8.0, 8.0}].CGPath;
    
    self.infoButton.layer.mask = topCornersMaskLayer;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) zoomToPointWithOffset:(CLLocationCoordinate2D) point {
    point.latitude -= self.mapView.region.span.latitudeDelta * (1.0/3.0);
    [self.mapView setCenterCoordinate:point animated:YES];
}



#pragma mark - Button actions
- (IBAction)showInfo:(id)sender {
    NSLog(@"Showing info drawer.");
    
    if (!self.settingsDrawerVisible) {
        self.settingsDrawerVisible = YES;
        [self.mapActionDelegate showMapInfoDrawer];
    }
}


- (IBAction)changeLocationState:(id)sender {
    NSLog(@"GPS button tapped");
    
    if (!self.showingUserLocation) {
        if (![CLLocationManager locationServicesEnabled]) {
            // todo show a message asking the user to enable it
            return;
        }
        
        switch ([CLLocationManager authorizationStatus]) {
            case kCLAuthorizationStatusAuthorizedWhenInUse:
                [self.locationManager startUpdatingLocation];
                [self.locationButton setImage:[UIImage imageNamed:@"GPSActive"] forState:UIControlStateNormal];
                self.showingUserLocation = YES;
                break;
            default:
                self.showingUserLocation = NO;
                [self.locationManager requestWhenInUseAuthorization];
                break;
        }
    } else {
        [self.locationManager stopUpdatingLocation];
        self.mapView.showsUserLocation = NO;
        self.showingUserLocation = NO;
        [self.locationButton setImage:[UIImage imageNamed:@"GPS"] forState:UIControlStateNormal];
    }
    
}


#pragma mark - Updaing the data on the map
- (void) updateMapLayers {
    [self updateInBackgroundWithZoom:YES];
}


#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *userLocation = [locations lastObject];

    if (self.showingUserLocation && !self.mapView.showsUserLocation && userLocation.coordinate.latitude != 0.0) {
        self.mapView.showsUserLocation = YES;
        [self zoomToPointWithOffset:userLocation.coordinate];
    } else if (self.showingUserLocation) {
        self.mapView.showsUserLocation = YES;
    } else {
        self.mapView.showsUserLocation = NO;
    }
}


#pragma mark - MCSettingsDelegate
- (void)setMapType:(NSString *)mapType {
    NSLog(@"In MCMapViewController handing setting map change");
    
    if ([mapType isEqualToString:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_STANDARD]]) {
        [self.mapView setMapType:MKMapTypeStandard];
        [self.settings setObject:mapType forKey:GPKGS_PROP_MAP_TYPE];
    } else if ([mapType isEqualToString:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_SATELLITE]]) {
        [self.mapView setMapType:MKMapTypeSatellite];
        [self.settings setObject:mapType forKey:GPKGS_PROP_MAP_TYPE];
    } else {
        [self.mapView setMapType:MKMapTypeHybrid];
        [self.settings setObject:mapType forKey:GPKGS_PROP_MAP_TYPE];
    }
    
    NSLog(@"NSUSerDefaults\n %@", [self.settings dictionaryRepresentation]);
}


- (void)setMaxFeatures:(int) maxFeatures {
    [self.settings setInteger:maxFeatures forKey:GPKGS_PROP_MAP_MAX_FEATURES];
    [self updateInBackgroundWithZoom:YES];
}


- (void)settingsCompletionHandler {
    self.settingsDrawerVisible = NO;
}


#pragma mark - MCTileHelperDelegate methods
- (void)addTileOverlayToMapView:(MKTileOverlay *)tileOverlay {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.mapView addOverlay:tileOverlay];
    });
}


#pragma mark - MCFeatureHelperDelegate methods
- (void) addShapeToMapView:(GPKGMapShape *) shape withCount:(int) count {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [GPKGMapShapeConverter addMapShape:shape toMapView:self.mapView];
    });
}


#pragma mark - MKMapViewDelegate methods
- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKOverlayRenderer * rendered = nil;
    if ([overlay isKindOfClass:[MKPolygon class]]) {
        MKPolygonRenderer * polygonRenderer = [[MKPolygonRenderer alloc] initWithPolygon:overlay];
        UIColor *strokeColor = self.defaultPolygonColor;
        double lineWidth = self.defaultPolygonLineWidth;
        UIColor *fillColor = self.defaultPolygonFillColor;
        if ([overlay isKindOfClass:[GPKGPolygon class]]) {
            GPKGPolygon *polygon = (GPKGPolygon *) overlay;
            GPKGPolygonOptions *options = polygon.options;
            if(options != nil){
                if(options.strokeColor != nil){
                    strokeColor = options.strokeColor;
                    fillColor = nil;
                }
                if(options.lineWidth > 0){
                    lineWidth = options.lineWidth;
                }
                if(options.fillColor != nil){
                    fillColor = options.fillColor;
                }
            }
        }
        polygonRenderer.strokeColor = strokeColor;
        polygonRenderer.lineWidth = lineWidth;
        if(fillColor != nil){
            polygonRenderer.fillColor = fillColor;
        }
        rendered = polygonRenderer;
    }else if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer * polylineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        UIColor *strokeColor = self.defaultPolylineColor;
        double lineWidth = self.defaultPolylineLineWidth;
        if ([overlay isKindOfClass:[GPKGPolyline class]]) {
            GPKGPolyline *polyline = (GPKGPolyline *) overlay;
            GPKGPolylineOptions *options = polyline.options;
            if(options != nil){
                if(options.strokeColor != nil){
                    strokeColor = options.strokeColor;
                }
                if(options.lineWidth > 0){
                    lineWidth = options.lineWidth;
                }
            }
        }
        polylineRenderer.strokeColor = strokeColor;
        polylineRenderer.lineWidth = lineWidth;
        rendered = polylineRenderer;
    }else if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        rendered = [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    }
    return rendered;
}


- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKAnnotationView * view = nil;
    
    if ([annotation isKindOfClass:[GPKGMapPoint class]]){
        
        GPKGMapPoint * mapPoint = (GPKGMapPoint *) annotation;
        
        if(mapPoint.options.image != nil){
            
            MKAnnotationView *mapPointImageView = (MKAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:mapPointImageReuseIdentifier];
            if (mapPointImageView == nil)
            {
                mapPointImageView = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:mapPointImageReuseIdentifier];
            }
            mapPointImageView.image = mapPoint.options.image;
            mapPointImageView.centerOffset = mapPoint.options.imageCenterOffset;
            
            view = mapPointImageView;
            
        }else{
            MKPinAnnotationView *mapPointPinView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:mapPointPinReuseIdentifier];
            if(mapPointPinView == nil){
                mapPointPinView = [[MKPinAnnotationView alloc]initWithAnnotation:annotation reuseIdentifier:mapPointPinReuseIdentifier];
            }
            mapPointPinView.pinTintColor = mapPoint.options.pinTintColor;
            view = mapPointPinView;
        }
        
        if(mapPoint.title == nil){
            [self.featureHelper setTitleWithMapPoint:mapPoint];
        }
        
        //UIButton *optionsButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
        //[optionsButton addTarget:self action:@selector(selectedMapPointOptions:) forControlEvents:UIControlEventTouchUpInside];
        
        //view.rightCalloutAccessoryView = optionsButton;
        view.canShowCallout = YES;
        
        view.draggable = mapPoint.options.draggable;
    }
    
    return view;
}


-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    int updateId = ++self.featureUpdateCountId;
    int featureUpdateId = [self.featureHelper getNewFeatureUpdateId];;
    int previousZoom = self.currentZoom;
    int zoom = (int)[GPKGMapUtils currentZoomWithMapView:mapView];
    self.currentZoom = zoom;
    
    if (zoom != previousZoom) {
        // Zoom level changed, remove all the feature shapes except the markers
        [self.featureHelper.featureShapes removeShapesFromMapView:mapView withExclusions:[[NSSet alloc] initWithObjects:[NSNumber numberWithInt:GPKG_MST_POINT], [NSNumber numberWithInt:GPKG_MST_MULTI_POINT], nil]];
    } else {
        // Remove shapes no longer visible on the map view
        [self.featureHelper.featureShapes removeShapesNotWithinMapView:mapView];
    }
    
    GPKGBoundingBox *mapViewBoundingBox = [GPKGMapUtils boundingBoxOfMapView:mapView];
    double toleranceDistance = [GPKGMapUtils toleranceDistanceInMapView:mapView];
    int maxFeatures = [self getMaxFeatures];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        if (self.active != nil) {
            [self.featureHelper prepareFeaturesWithUpdateId:(int) updateId andFeatureUpdateId:(int) featureUpdateId andZoom:(int) zoom andMaxFeatures:(int) maxFeatures andMapViewBoundingBox:(GPKGBoundingBox *) mapViewBoundingBox andToleranceDistance:(double) toleranceDistance andFilter:(BOOL) YES];
        }
    });
}


#pragma mark - Zoom and map state
-(int) updateInBackgroundWithZoom: (BOOL) zoom{
    return [self updateInBackgroundWithZoom:zoom andFilter:false];
}


// Lots of mapview stuff in here, most of this can stay
-(int) updateInBackgroundWithZoom: (BOOL) zoom andFilter: (BOOL) filter{
    int updateId = [self.featureHelper getNewUpdateId];
    int featureUpdateId = [self.featureHelper getNewFeatureUpdateId];;
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    for(GPKGGeoPackage * geoPackage in [self.geoPackages allValues]){
        @try {
            [geoPackage close];
        }
        @catch (NSException *exception) {
        }
    }
    [self.geoPackages removeAllObjects];
    [self.featureDaos removeAllObjects];
    
    if(zoom){
        [self zoomToActiveBounds];
    }
    
    self.featuresBoundingBox = nil;
    self.tilesBoundingBox = nil;
    self.featureOverlayTiles = false;
    //[self.featureOverlayQueries removeAllObjects];
    //[self.featureShapes clear];
    int maxFeatures = [self getMaxFeatures];
    
    GPKGBoundingBox *mapViewBoundingBox = [GPKGMapUtils boundingBoxOfMapView:self.mapView];
    double toleranceDistance = [GPKGMapUtils toleranceDistanceInMapView:self.mapView];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
         if (self.active != nil) {
              [self.tileHelper prepareTiles];
              [self.featureHelper prepareFeaturesWithUpdateId:(int) updateId andFeatureUpdateId:(int) featureUpdateId andZoom:(int) zoom andMaxFeatures:(int) maxFeatures andMapViewBoundingBox:(GPKGBoundingBox *) mapViewBoundingBox andToleranceDistance:(double) toleranceDistance andFilter:(BOOL) filter];
        }
    });
}


-(void) updateFeaturesBoundingBox: (GPKGMapShape *) shape
{
    if(self.featuresBoundingBox != nil){
        [shape expandBoundingBox:self.featuresBoundingBox];
    }else{
        self.featuresBoundingBox = [shape boundingBox];
    }
}


-(void) zoomToActive{
    [self zoomToActiveIfNothingVisible:NO];
}

-(void) zoomToActiveAndIgnoreRegionChange: (BOOL) ignoreChange{
    [self zoomToActiveIfNothingVisible:NO andIgnoreRegionChange:ignoreChange];
}

-(void) zoomToActiveIfNothingVisible: (BOOL) nothingVisible{
    [self zoomToActiveIfNothingVisible:nothingVisible andIgnoreRegionChange:NO];
}

-(void) zoomToActiveIfNothingVisible: (BOOL) nothingVisible andIgnoreRegionChange: (BOOL) ignoreChange{
    
    GPKGBoundingBox * bbox = self.featuresBoundingBox;
    BOOL tileBox = false;
    
    float paddingPercentage;
    if(bbox == nil){
        bbox = self.tilesBoundingBox;
        tileBox = true;
        if(self.featureOverlayTiles){
            paddingPercentage = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_FEATURE_TILES_ZOOM_PADDING_PERCENTAGE] intValue] * .01;
        }else{
            paddingPercentage = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_TILES_ZOOM_PADDING_PERCENTAGE] intValue] * .01;
        }
    }else{
        paddingPercentage = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_FEATURES_ZOOM_PADDING_PERCENTAGE] intValue] * .01f;
    }
    
    if(bbox != nil){
        
        BOOL zoomToActive = YES;
        if(nothingVisible){
            GPKGBoundingBox *mapViewBoundingBox = [GPKGMapUtils boundingBoxOfMapView:self.mapView];
            if([GPKGTileBoundingBoxUtils overlapWithBoundingBox:bbox andBoundingBox:mapViewBoundingBox withMaxLongitude:PROJ_WGS84_HALF_WORLD_LON_WIDTH] != nil){
                
                struct GPKGBoundingBoxSize bboxSize = [bbox sizeInMeters];
                struct GPKGBoundingBoxSize mapViewSize = [mapViewBoundingBox sizeInMeters];
                
                double longitudeDistance = bboxSize.width;
                double latitudeDistance = bboxSize.height;
                double mapViewLongitudeDistance = mapViewSize.width;
                double mapViewLatitudeDistance = mapViewSize.height;
                
                if (mapViewLongitudeDistance > longitudeDistance && mapViewLatitudeDistance > latitudeDistance) {
                    
                    double longitudeRatio = longitudeDistance / mapViewLongitudeDistance;
                    double latitudeRatio = latitudeDistance / mapViewLatitudeDistance;
                    
                    double zoomAlreadyVisiblePercentage;
                    if (tileBox) {
                        zoomAlreadyVisiblePercentage = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_TILES_ZOOM_ALREADY_VISIBLE_PERCENTAGE] intValue] * .01;
                    }else{
                        zoomAlreadyVisiblePercentage = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_FEATURES_ZOOM_ALREADY_VISIBLE_PERCENTAGE] intValue] * .01;
                    }
                    
                    if(longitudeRatio >= zoomAlreadyVisiblePercentage && latitudeRatio >= zoomAlreadyVisiblePercentage){
                        zoomToActive = false;
                    }
                }
            }
        }
        
        if(zoomToActive){
            struct GPKGBoundingBoxSize size = [bbox sizeInMeters];
            double expandedHeight = size.height + (2 * (size.height * paddingPercentage));
            double expandedWidth = size.width + (2 * (size.width * paddingPercentage));
            
            CLLocationCoordinate2D center = [bbox getCenter];
            MKCoordinateRegion expandedRegion = MKCoordinateRegionMakeWithDistance(center, expandedHeight, expandedWidth);
            
            double latitudeRange = expandedRegion.span.latitudeDelta / 2.0;
            
            if(expandedRegion.center.latitude + latitudeRange > 90.0 || expandedRegion.center.latitude - latitudeRange < -90.0){
                expandedRegion = MKCoordinateRegionMake(self.mapView.centerCoordinate, MKCoordinateSpanMake(180, 360));
            }
            
//            if(ignoreChange){
//                self.ignoreRegionChange = true;
//            }
            [self.mapView setRegion:expandedRegion animated:true];
        }
    }
}


-(void) zoomToActiveBounds{
    
    self.featuresBoundingBox = nil;
    self.tilesBoundingBox = nil;
    
    // Pre zoom
    NSMutableArray *activeDatabase = [[NSMutableArray alloc] init];
    [activeDatabase addObjectsFromArray:[self.active getDatabases]];
    for(GPKGSDatabase *database in activeDatabase){
        GPKGGeoPackage *geoPackage = [self.manager open:database.name];
        if (geoPackage != nil) {
            
            NSMutableSet<NSString *> *featureTableDaos = [[NSMutableSet alloc] init];
            NSArray *features = [database getFeatures];
            if(features.count > 0){
                for(GPKGSTable *featureTable in features){
                    [featureTableDaos addObject:featureTable.name];
                }
            }
            
            for(GPKGSFeatureOverlayTable * featureOverlay in [database getFeatureOverlays]){
                if(featureOverlay.active){
                    [featureTableDaos addObject:featureOverlay.featureTable];
                }
            }
            
            if(featureTableDaos.count > 0){
                
                GPKGContentsDao *contentsDao = [geoPackage getContentsDao];
                
                for (NSString *featureTable in featureTableDaos) {
                    
                    @try {
                        GPKGContents *contents = (GPKGContents *)[contentsDao queryForIdObject:featureTable];
                        GPKGBoundingBox *contentsBoundingBox = [contents getBoundingBox];
                        
                        if (contentsBoundingBox != nil) {
                            
                            contentsBoundingBox = [self.tileHelper transformBoundingBoxToWgs84: contentsBoundingBox withSrs: [contentsDao getSrs:contents]];
                            
                            if (self.featuresBoundingBox != nil) {
                                self.featuresBoundingBox = [self.featuresBoundingBox union:contentsBoundingBox];
                            } else {
                                self.featuresBoundingBox = contentsBoundingBox;
                            }
                        }
                    } @catch (NSException *e) {
                        NSLog(@"%@", [e description]);
                    } @finally {
                        [geoPackage close];
                    }
                }
            }
            
            NSArray *tileTables = [database getTiles];
            if(tileTables.count > 0){
                
                GPKGTileMatrixSetDao *tileMatrixSetDao = [geoPackage getTileMatrixSetDao];
                
                for(GPKGSTileTable *tileTable in tileTables){
                    
                    @try {
                        GPKGTileMatrixSet *tileMatrixSet = (GPKGTileMatrixSet *)[tileMatrixSetDao queryForIdObject:tileTable.name];
                        GPKGBoundingBox *tileMatrixSetBoundingBox = [tileMatrixSet getBoundingBox];
                        
                        tileMatrixSetBoundingBox = [self.tileHelper transformBoundingBoxToWgs84:tileMatrixSetBoundingBox withSrs:[tileMatrixSetDao getSrs:tileMatrixSet]];
                        
                        if (self.tilesBoundingBox != nil) {
                            self.tilesBoundingBox = [self.tilesBoundingBox union:tileMatrixSetBoundingBox];
                        } else {
                            self.tilesBoundingBox = tileMatrixSetBoundingBox;
                        }
                    } @catch (NSException *e) {
                        NSLog(@"%@", [e description]);
                    } @finally {
                        [geoPackage close];
                    }
                }
            }
            
            [geoPackage close];
        }
    }
    [self zoomToActiveAndIgnoreRegionChange:YES];
}


-(int) getMaxFeatures{
    int maxFeatures = (int)[self.settings integerForKey:GPKGS_PROP_MAP_MAX_FEATURES];
    if(maxFeatures == 0){
        maxFeatures = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_MAX_FEATURES_DEFAULT] intValue];
    }
    return maxFeatures;
}


- (void) setupColors {
    self.boundingBoxColor = [GPKGUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_BOUNDING_BOX_DRAW_COLOR]];
    self.boundingBoxLineWidth = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_BOUNDING_BOX_DRAW_LINE_WIDTH] doubleValue];
    if([GPKGSProperties getBoolOfProperty:GPKGS_PROP_BOUNDING_BOX_DRAW_FILL]){
        self.boundingBoxFillColor = [GPKGUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_BOUNDING_BOX_DRAW_FILL_COLOR]];
    }
    
    self.defaultPolylineColor = [GPKGUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_DEFAULT_POLYLINE_COLOR]];
    self.defaultPolylineLineWidth = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_DEFAULT_POLYLINE_LINE_WIDTH] doubleValue];
    
    self.defaultPolygonColor = [GPKGUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_DEFAULT_POLYGON_COLOR]];
    self.defaultPolygonLineWidth = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_DEFAULT_POLYGON_LINE_WIDTH] doubleValue];
    if([GPKGSProperties getBoolOfProperty:GPKGS_PROP_DEFAULT_POLYGON_FILL]){
        self.defaultPolygonFillColor = [GPKGUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_DEFAULT_POLYGON_FILL_COLOR]];
    }
    
    self.editPolylineColor = [GPKGUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_EDIT_POLYLINE_COLOR]];
    self.editPolylineLineWidth = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_EDIT_POLYLINE_LINE_WIDTH] doubleValue];
    
    self.editPolygonColor = [GPKGUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_EDIT_POLYGON_COLOR]];
    self.editPolygonLineWidth = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_EDIT_POLYGON_LINE_WIDTH] doubleValue];
    if([GPKGSProperties getBoolOfProperty:GPKGS_PROP_EDIT_POLYGON_FILL]){
        self.editPolygonFillColor = [GPKGUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_EDIT_POLYGON_FILL_COLOR]];
    }
    
    self.drawPolylineColor = [GPKGUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_DRAW_POLYLINE_COLOR]];
    self.drawPolylineLineWidth = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_DRAW_POLYLINE_LINE_WIDTH] doubleValue];
    
    self.drawPolygonColor = [GPKGUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_DRAW_POLYGON_COLOR]];
    self.drawPolygonLineWidth = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_DRAW_POLYGON_LINE_WIDTH] doubleValue];
    if([GPKGSProperties getBoolOfProperty:GPKGS_PROP_DRAW_POLYGON_FILL]){
        self.drawPolygonFillColor = [GPKGUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_DRAW_POLYGON_FILL_COLOR]];
    }
}


#pragma mark - Bounding Box methods for creating new tile layers
- (void) enableBoundingBoxMode {
    NSLog(@"MCMapController - going into bounding box mode");
    
    self.boundingBoxMode = YES;
    
}


-(void) longPressGesture:(UILongPressGestureRecognizer *) longPressGestureRecognizer {
    NSLog(@"Getting a long press gesture.");
    
    CGPoint cgPoint = [longPressGestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D point = [self.mapView convertPoint:cgPoint toCoordinateFromView:self.mapView];
    
    if(self.boundingBoxMode){
        NSLog(@"Bounding Box mode");
        if(longPressGestureRecognizer.state == UIGestureRecognizerStateBegan){
            //[_editBoundingBoxButton setTitle:@"Edit Bounding Box" forState:UIControlStateNormal];
            
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
                self.boundingBox = [GPKGPolygon polygonWithCoordinates:points count:4];
                
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
                            GPKGPolygon * newBoundingBox = [GPKGPolygon polygonWithCoordinates:points count:4];
                            [self.mapView removeOverlay:self.boundingBox];
                            [self.mapView addOverlay:newBoundingBox];
                            self.boundingBox = newBoundingBox;
                            //_nextButton.enabled = YES;
                            self.navigationItem.prompt = @"You can drag the corners of the bounding box to adjust it.";
                            
                            if (_boundingBoxStartCorner.latitude > _boundingBoxEndCorner.latitude) {
                                _minLat = _boundingBoxEndCorner.latitude;
                                _maxLat = _boundingBoxStartCorner.latitude;
                                
                                //_upperRightLatitudeLabel.text = [NSString stringWithFormat:@"Lat: %.2f", self.boundingBoxStartCorner.latitude];
                                //_lowerLeftLatitudeLabel.text = [NSString stringWithFormat:@"Lat: %.2f", self.boundingBoxEndCorner.latitude];
                            } else {
                                _minLat = _boundingBoxStartCorner.latitude;
                                _maxLat = _boundingBoxEndCorner.latitude;
                                
                                //_upperRightLatitudeLabel.text = [NSString stringWithFormat:@"Lat: %.2f", self.boundingBoxEndCorner.latitude];
                                //_lowerLeftLatitudeLabel.text = [NSString stringWithFormat:@"Lat: %.2f", self.boundingBoxStartCorner.latitude];
                            }
                            
                            if (_boundingBoxStartCorner.longitude < _boundingBoxEndCorner.longitude) {
                                _minLon = _boundingBoxStartCorner.longitude;
                                _maxLon = _boundingBoxEndCorner.longitude;
                                
                                //_lowerLeftLongitudeLabel.text = [NSString stringWithFormat:@"Lon: %.2f", self.boundingBoxStartCorner.longitude];
                                //_upperRightLongitudeLabel.text = [NSString stringWithFormat:@"Lon: %.2f", self.boundingBoxEndCorner.longitude];
                            } else {
                                _minLon = _boundingBoxEndCorner.longitude;
                                _maxLon = _boundingBoxStartCorner.longitude;
                                
                                //_lowerLeftLongitudeLabel.text = [NSString stringWithFormat:@"Lon: %.2f", self.boundingBoxEndCorner.longitude];
                                //_upperRightLongitudeLabel.text = [NSString stringWithFormat:@"Lon: %.2f", self.boundingBoxStartCorner.longitude];
                            }
                            
                            
//                            [self animateShowHide:_lowerLeftLabel :NO];
//                            [self animateShowHide:_upperRightLabel :NO];
//                            [self animateShowHide:_lowerLeftLatitudeLabel :NO];
//                            [self animateShowHide:_lowerLeftLongitudeLabel :NO];
//                            [self animateShowHide:_upperRightLatitudeLabel :NO];
//                            [self animateShowHide:_upperRightLongitudeLabel :NO];
                        }
                        if(longPressGestureRecognizer.state == UIGestureRecognizerStateEnded){
                            [self setDrawing:false];
                            
                            GPKGBoundingBox *boundingBox = [[GPKGBoundingBox alloc] initWithMinLongitude:[[NSDecimalNumber alloc] initWithDouble:_minLon]
                                                                                          andMinLatitude:[[NSDecimalNumber alloc] initWithDouble:_minLat]
                                                                                         andMaxLongitude:[[NSDecimalNumber alloc] initWithDouble:_maxLon]
                                                                                          andMaxLatitude:[[NSDecimalNumber alloc] initWithDouble:_maxLat]];
                            
                            NSDictionary *boundingBoxResults = @{@"boundingBox": boundingBox};
                            
                            // MCBoundingBoxDetailsViewController is on the recieving end
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"boundingBoxResults" object:self userInfo:boundingBoxResults];
                        }
                    }
                    break;
                default:
                    break;
            }
        }
    }
    /*else if(self.editFeatureType != GPKGS_ET_NONE){
        
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
    }*/
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


@end
