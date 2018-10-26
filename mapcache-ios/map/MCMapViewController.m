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
@property (nonatomic, strong) NSMutableDictionary * featureDaos;
@property (nonatomic, strong) GPKGBoundingBox * featuresBoundingBox;
@property (nonatomic, strong) GPKGBoundingBox * tilesBoundingBox;
@property (nonatomic) BOOL featureOverlayTiles;
@property (atomic) int updateCountId;
@property (atomic) int featureUpdateCountId;
@property (nonatomic, strong) GPKGFeatureShapes * featureShapes;
@property (nonatomic) BOOL needsInitialZoom;
@property (nonatomic, strong) UIColor * boundingBoxColor;
@property (nonatomic) double boundingBoxLineWidth;
@property (nonatomic, strong) UIColor * boundingBoxFillColor;
@property (nonatomic, strong) UIColor * defaultPolylineColor;
@property (nonatomic) double defaultPolylineLineWidth;
@property (nonatomic, strong) UIColor * defaultPolygonColor;
@property (nonatomic) double defaultPolygonLineWidth;
@property (nonatomic, strong) UIColor * defaultPolygonFillColor;
@property (nonatomic, strong) UIColor * editPolylineColor;
@property (nonatomic) double editPolylineLineWidth;
@property (nonatomic, strong) UIColor * editPolygonColor;
@property (nonatomic) double editPolygonLineWidth;
@property (nonatomic, strong) UIColor * editPolygonFillColor;
@property (nonatomic, strong) UIColor * drawPolylineColor;
@property (nonatomic) double drawPolylineLineWidth;
@property (nonatomic, strong) UIColor * drawPolygonColor;
@property (nonatomic) double drawPolygonLineWidth;
@property (nonatomic, strong) UIColor * drawPolygonFillColor;
@property (nonatomic, strong) NSNumberFormatter *locationDecimalFormatter;
@end


@implementation MCMapViewController

static NSString *mapPointImageReuseIdentifier = @"mapPointImageReuseIdentifier";
static NSString *mapPointPinReuseIdentifier = @"mapPointPinReuseIdentifier";

- (void)viewDidLoad {
    [super viewDidLoad];
    _childCoordinators = [[NSMutableArray alloc] init];
    
    self.mapView.delegate = self;
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
    self.featureHelper = [[MCFeatureHelper alloc] init];
    
    self.locationDecimalFormatter = [[NSNumberFormatter alloc] init];
    self.locationDecimalFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    self.locationDecimalFormatter.maximumFractionDigits = 4;
    
    [self.view setNeedsLayout];
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


- (void) addBottomSheetView {
    NGADrawerCoordinator *drawerCoordinator = [[NGADrawerCoordinator alloc] init];
    [drawerCoordinator start];
    [_childCoordinators addObject: drawerCoordinator];
}


#pragma mark - Button actions
- (IBAction)showInfo:(id)sender {
}


- (IBAction)changeLocationState:(id)sender {
}


#pragma mark - Updaing the data on the map
- (void) updateMapLayers {
    [self updateInBackgroundWithZoom:YES];
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


- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    MKOverlayRenderer * rendered = nil;
    if ([overlay isKindOfClass:[MKPolygon class]]) {
        MKPolygonRenderer * polygonRenderer = [[MKPolygonRenderer alloc] initWithPolygon:overlay];
        polygonRenderer.strokeColor = self.defaultPolygonColor;
        polygonRenderer.lineWidth = self.defaultPolygonLineWidth;
        
        if(self.defaultPolygonFillColor != nil){
            polygonRenderer.fillColor = self.defaultPolygonFillColor;
        }
        
        rendered = polygonRenderer;
    } else if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer * polylineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        polylineRenderer.strokeColor = self.defaultPolylineColor;
        polylineRenderer.lineWidth = self.defaultPolylineLineWidth;
        rendered = polylineRenderer;
    } else if ([overlay isKindOfClass:[MKTileOverlay class]]) {
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


#pragma mark - MCTileHelperDelegate methods
- (void) addTileOverlayToMapView:(MKTileOverlay *)tileOverlay {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.mapView addOverlay:tileOverlay];
    });
}


-(int) updateInBackgroundWithZoom: (BOOL) zoom{
    return [self updateInBackgroundWithZoom:zoom andFilter:false];
}


// Lots of mapview stuff in here, most of this can stay
-(int) updateInBackgroundWithZoom: (BOOL) zoom andFilter: (BOOL) filter{
    int updateId = ++self.updateCountId;
    int featureUpdateId = ++self.featureUpdateCountId;
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
    
//    if(zoom){
//        [self zoomToActiveBounds];
//    }
    
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
        [self updateWithId: updateId andFeatureUpdateId:featureUpdateId andZoom:zoom andMaxFeatures:maxFeatures andMapViewBoundingBox:mapViewBoundingBox andToleranceDistance:toleranceDistance andFilter:filter];
    });
}


// Much data manipulation and transformation, look at moving into utility class
-(int) updateWithId: (int) updateId andFeatureUpdateId: (int) featureUpdateId andZoom: (BOOL) zoom andMaxFeatures: (int) maxFeatures andMapViewBoundingBox: (GPKGBoundingBox *) mapViewBoundingBox andToleranceDistance: (double) toleranceDistance andFilter: (BOOL) filter{
    
    int count = 0;
    
    if(self.active != nil){
        
        NSArray * activeDatabases = [[NSArray alloc] initWithArray:[self.active getDatabases]];
        
        // Open active GeoPackages and create feature DAOS, display tiles and feature tiles
        for(GPKGSDatabase * database in activeDatabases){
            
//            if([self updateCanceled:updateId]){
//                break;
//            }
            
            GPKGGeoPackage * geoPackage = [self.manager open:database.name];
            
            if(geoPackage != nil){
                [self.geoPackages setObject:geoPackage forKey:database.name];
                
                NSMutableSet * featureTableDaos = [[NSMutableSet alloc] init];
                NSArray * features = [database getFeatures];
                if([features count] > 0){
                    for(GPKGSTable * features in [database getFeatures]){
                        [featureTableDaos addObject:features.name];
                    }
                }
                
                for(GPKGSFeatureOverlayTable * featureOverlay in [database getFeatureOverlays]){
                    if(featureOverlay.active){
                        [featureTableDaos addObject:featureOverlay.featureTable];
                    }
                }
                
                if(featureTableDaos.count > 0){
                    NSMutableDictionary * databaseFeatureDaos = [[NSMutableDictionary alloc] init];
                    [self.featureDaos setObject:databaseFeatureDaos forKey:database.name];
                    for(NSString *featureTable in featureTableDaos){
                        
//                        if([self updateCanceled:updateId]){
//                            break;
//                        }
                        
                        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:featureTable];
                        [databaseFeatureDaos setObject:featureDao forKey:featureTable];
                    }
                }
                
                // Get the tile data ready. The helper will call back this delegate when the data is ready to display.
                [self.tileHelper prepareTiles];

                
                // Display the feature tiles
                for(GPKGSFeatureOverlayTable * featureOverlay in [database getFeatureOverlays]){
//                    if([self updateCanceled:updateId]){
//                        break;
//                    }
                    if(featureOverlay.active){
                        @try {
//                            [self displayFeatureTiles:featureOverlay];
                        }
                        @catch (NSException *e) {
                            NSLog(@"%@", [e description]);
                        }
                    }
                }
                
            } else{
                [self.active removeDatabase:database.name andPreserveOverlays:false];
            }
        }
        
        // Add features
        if(![self featureUpdateCanceled:featureUpdateId]){
            count = [self addFeaturesWithId:featureUpdateId andMaxFeatures:maxFeatures andMapViewBoundingBox:mapViewBoundingBox andToleranceDistance:toleranceDistance andFilter:filter];
        }
    }
    
//    if(self.boundingBox != nil){
//        [self.mapView addOverlay:self.boundingBox];
//    }
    
    if(self.needsInitialZoom || zoom){
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self zoomToActiveIfNothingVisible:YES];
            self.needsInitialZoom = false;
        });
    }
    
    return count;
}


-(BOOL) featureUpdateCanceled: (int) updateId{
    BOOL canceled = updateId < self.featureUpdateCountId;
    return canceled;
}


-(int) addFeaturesWithId: (int) updateId andMaxFeatures: (int) maxFeatures andMapViewBoundingBox: (GPKGBoundingBox *) mapViewBoundingBox andToleranceDistance: (double) toleranceDistance andFilter: (BOOL) filter{
    
    int count = 0;
    
    // Add features
    NSMutableDictionary * featureTables = [[NSMutableDictionary alloc] init];
//    if(self.editFeaturesMode){
//        NSMutableArray * databaseFeatures = [[NSMutableArray alloc] init];
//        [databaseFeatures addObject:self.editFeaturesTable];
//        [featureTables setObject:databaseFeatures forKey:self.editFeaturesDatabase];
//        GPKGGeoPackage * geoPackage = [self.geoPackages objectForKey:self.editFeaturesDatabase];
//        if(geoPackage == nil){
//            geoPackage = [self.manager open:self.editFeaturesDatabase];
//            [self.geoPackages setObject:geoPackage forKey:self.editFeaturesDatabase];
//        }
//        NSMutableDictionary * databaseFeatureDaos = [self.featureDaos objectForKey:self.editFeaturesDatabase];
//        if(databaseFeatureDaos == nil){
//            databaseFeatureDaos = [[NSMutableDictionary alloc] init];
//            [self.featureDaos setObject:databaseFeatureDaos forKey:self.editFeaturesDatabase];
//        }
//        GPKGFeatureDao * featureDao = [databaseFeatureDaos objectForKey:self.editFeaturesTable];
//        if(featureDao == nil){
//            featureDao = [geoPackage getFeatureDaoWithTableName:self.editFeaturesTable];
//            [databaseFeatureDaos setObject:featureDao forKey:self.editFeaturesTable];
//        }
//    }else{
        for(GPKGSDatabase * database in [self.active getDatabases]){
            NSArray * features = [database getFeatures];
            if([features count] > 0){
                NSMutableArray * databaseFeatures = [[NSMutableArray alloc] init];
                [featureTables setObject:databaseFeatures forKey:database.name];
                for(GPKGSTable * features in [database getFeatures]){
                    [databaseFeatures addObject:features.name];
                }
            }
        }
//    }
    
    for(NSString * databaseName in [featureTables allKeys]){
        
        if(count >= maxFeatures){
            break;
        }
        
        if([self.geoPackages objectForKey:databaseName] != nil){
            
            NSMutableArray * databaseFeatures = [featureTables objectForKey:databaseName];
            
            for(NSString * features in databaseFeatures){
                
                if([[self.featureDaos objectForKey:databaseName] objectForKey:features] != nil){
                    
                    count = [self displayFeaturesWithId:updateId andDatabase:databaseName andFeatures:features andCount:count andMaxFeatures:maxFeatures andEditable:NO andMapViewBoundingBox:mapViewBoundingBox andToleranceDistance:toleranceDistance andFilter:filter];
                    if([self featureUpdateCanceled:updateId] || count >= maxFeatures){
                        break;
                    }
                }
            }
        }
        
        if([self featureUpdateCanceled:updateId]){
            break;
        }
    }
    
    return count;
}


-(int) displayFeaturesWithId: (int) updateId andDatabase: (NSString *) database andFeatures: (NSString *) features andCount: (int) count andMaxFeatures: (int) maxFeatures andEditable: (BOOL) editable andMapViewBoundingBox: (GPKGBoundingBox *) mapViewBoundingBox andToleranceDistance: (double) toleranceDistance andFilter: (BOOL) filter{
    
    GPKGGeoPackage * geoPackage = [self.geoPackages objectForKey:database];
    GPKGFeatureDao * featureDao = [[self.featureDaos objectForKey:database] objectForKey:features];
    NSString * tableName = featureDao.tableName;
    GPKGMapShapeConverter * converter = [[GPKGMapShapeConverter alloc] initWithProjection:featureDao.projection];
    
    [converter setSimplifyToleranceAsDouble:toleranceDistance];
    
    count += [self.featureShapes featureIdsCountInDatabase:database withTable:tableName];
    
    if(![self featureUpdateCanceled:updateId] && count < maxFeatures){
        
        SFPProjection *mapViewProjection = [SFPProjectionFactory projectionWithEpsgInt: PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
        
        GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
        if(filter && [indexer isIndexed]){
            
            GPKGFeatureIndexResults *indexResults = [indexer queryWithBoundingBox:mapViewBoundingBox inProjection:mapViewProjection];
            GPKGBoundingBox *complementary = [mapViewBoundingBox complementaryWgs84];
            if(complementary != nil){
                GPKGFeatureIndexResults *indexResults2 = [indexer queryWithBoundingBox:complementary inProjection:mapViewProjection];
                indexResults = [[GPKGMultipleFeatureIndexResults alloc] initWithFeatureIndexResults1:indexResults andFeatureIndexResults2:indexResults2];
            }
            count = [self processFeatureIndexResults:indexResults withUpdateId:updateId andDatabase:database andCount:count andMaxFeatures:maxFeatures andEditable:editable andTableName:tableName andConverter:converter andFilter:filter];
            
        }else{
            
            GPKGBoundingBox *filterBoundingBox = nil;
            double filterMaxLongitude = 0;
            
            if(filter){
                SFPProjection *featureProjection = featureDao.projection;
                SFPProjectionTransform * projectionTransform = [[SFPProjectionTransform alloc] initWithFromProjection:mapViewProjection andToProjection:featureProjection];
                GPKGBoundingBox *boundedMapViewBoundingBox = [mapViewBoundingBox boundWgs84Coordinates];
                GPKGBoundingBox *transformedBoundingBox = [boundedMapViewBoundingBox transform:projectionTransform];
                enum SFPUnit unit = [featureProjection getUnit];
                if(unit == SFP_UNIT_DEGREES){
                    filterMaxLongitude = PROJ_WGS84_HALF_WORLD_LON_WIDTH;
                }else if(unit == SFP_UNIT_METERS){
                    filterMaxLongitude = PROJ_WEB_MERCATOR_HALF_WORLD_WIDTH;
                }
                filterBoundingBox = [transformedBoundingBox expandCoordinatesWithMaxLongitude:filterMaxLongitude];
            }
            
            // Query for all rows
            GPKGResultSet * results = [featureDao queryForAll];
            @try {
                while(![self featureUpdateCanceled:updateId] && count < maxFeatures && [results moveToNext]){
                    @try {
                        GPKGFeatureRow * row = [featureDao getFeatureRow:results];
                        
                        
                        // TODO update getting shape and adding to map, calculate count here
                        //count = [self processFeatureRow:row withDatabase:database andCount:count andMaxFeatures:maxFeatures andEditable:editable andTableName:tableName andConverter:converter andFilterBoundingBox:filterBoundingBox andFilterMaxLongitude:filterMaxLongitude andFilter:filter];
                        
                        GPKGMapShape *shape = [self.featureHelper processFeatureRow:row WithDatabase:database andTableName:tableName andConverter:converter andCount:count andMaxFeatures:maxFeatures andEditable:editable andFilterBoundingBox:filterBoundingBox andFilterMaxLongitude:filterMaxLongitude andFilter:filter];
                        
                        if (shape != nil && count++ < maxFeatures) {
                            dispatch_sync(dispatch_get_main_queue(), ^{
                                [GPKGMapShapeConverter addMapShape:shape toMapView:self.mapView];
                            });
                        }
                        
                        
                    } @catch (NSException *exception) {
                        NSLog(@"Failed to display feature. database: %@, feature table: %@, error: %@", database, features, [exception description]);
                    }
                }
            }
            @finally {
                [results close];
            }
        }
    }
    
    return count;
}


-(int) processFeatureIndexResults: (GPKGFeatureIndexResults *) indexResults withUpdateId: (int) updateId andDatabase: (NSString *) database andCount: (int) count andMaxFeatures: (int) maxFeatures andEditable: (BOOL) editable andTableName: (NSString *) tableName andConverter: (GPKGMapShapeConverter *) converter andFilter: (BOOL) filter{
    
    @try {
        for(GPKGFeatureRow *row in indexResults){
            
            if([self featureUpdateCanceled:updateId] || count >= maxFeatures){
                break;
            }
            
            if(![self.featureHelper.featureShapes existsWithFeatureId:[row getId] inDatabase:database withTable:tableName]){
                GPKGMapShape *shape = [self.featureHelper processFeatureRow:row WithDatabase:database andTableName:tableName andConverter:converter andCount:count andMaxFeatures:maxFeatures andEditable:editable andFilterBoundingBox:nil andFilterMaxLongitude:0 andFilter:filter];
                
                if (shape != nil && count++ < maxFeatures) {
                    dispatch_sync(dispatch_get_main_queue(), ^{
                        [GPKGMapShapeConverter addMapShape:shape toMapView:self.mapView];
                    });
                }
            }
        }
    }
    @finally {
        [indexResults close];
    }
    
    return count;
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

@end
