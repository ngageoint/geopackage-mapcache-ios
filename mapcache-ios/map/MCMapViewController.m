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
    self.tileHelper = [[MCTileHelper alloc] init];
    
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
            [self setTitleWithMapPoint:mapPoint];
        }
        
        //UIButton *optionsButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
        //[optionsButton addTarget:self action:@selector(selectedMapPointOptions:) forControlEvents:UIControlEventTouchUpInside];
        
        //view.rightCalloutAccessoryView = optionsButton;
        view.canShowCallout = YES;
        
        view.draggable = mapPoint.options.draggable;
    }
    
    return view;
}


-(void) setTitleWithMapPoint: (GPKGMapPoint *) mapPoint{
    [self setTitleWithTitle:nil andMapPoint:mapPoint];
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
                
                // Display the tiles
                for(GPKGSTileTable * tiles in [database getTiles]){
//                    if([self updateCanceled:updateId]){
//                        break;
//                    }
                    @try {
                        [self displayTiles:tiles];
                    }
                    @catch (NSException *e) {
                        NSLog(@"%@", [e description]);
                    }
                }
                
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


-(void) displayTiles: (GPKGSTileTable *) tiles{
    GPKGGeoPackage * geoPackage = [self.geoPackages objectForKey:tiles.database];
    GPKGTileDao * tileDao = [geoPackage getTileDaoWithTableName:tiles.name];
    GPKGTileTableScaling *tileTableScaling = [[GPKGTileTableScaling alloc] initWithGeoPackage:geoPackage andTileDao:tileDao];
    GPKGTileScaling *tileScaling = [tileTableScaling get];
    GPKGBoundedOverlay * overlay = [GPKGOverlayFactory boundedOverlay:tileDao andScaling:tileScaling];
    overlay.canReplaceMapContent = false;
    
    GPKGTileMatrixSet * tileMatrixSet = tileDao.tileMatrixSet;
    
//    GPKGFeatureTileTableLinker * linker = [[GPKGFeatureTileTableLinker alloc] initWithGeoPackage:geoPackage];
//    NSArray<GPKGFeatureDao *> * featureDaos = [linker getFeatureDaosForTileTable:tileDao.tableName];
//    for(GPKGFeatureDao * featureDao in featureDaos){
//
//        // Create the feature tiles
//        GPKGFeatureTiles * featureTiles = [[GPKGFeatureTiles alloc] initWithFeatureDao:featureDao];
//
//        // Create an index manager
//        GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
//        [featureTiles setIndexManager:indexer];
//
//        self.featureOverlayTiles = true;
//
//        // Add the feature overlay query
////        GPKGFeatureOverlayQuery * featureOverlayQuery = [[GPKGFeatureOverlayQuery alloc] initWithBoundedOverlay:overlay andFeatureTiles:featureTiles];
//        [self.featureOverlayQueries addObject:featureOverlayQuery];
//    }
    
    GPKGBoundingBox *displayBoundingBox = [tileMatrixSet getBoundingBox];
    GPKGTileMatrixSetDao * tileMatrixSetDao = [geoPackage getTileMatrixSetDao];
    GPKGSpatialReferenceSystem *tileMatrixSetSrs = [tileMatrixSetDao getSrs:tileMatrixSet];
    GPKGContents *contents = [tileMatrixSetDao getContents:tileMatrixSet];
    GPKGBoundingBox *contentsBoundingBox = [contents getBoundingBox];
    if(contentsBoundingBox != nil){
        GPKGContentsDao *contentsDao = [geoPackage getContentsDao];
        SFPProjectionTransform *transform = [[SFPProjectionTransform alloc] initWithFromProjection:[[contentsDao getSrs:contents] projection] andToProjection:[tileMatrixSetSrs projection]];
        GPKGBoundingBox *transformedContentsBoundingBox = contentsBoundingBox;
        if(![transform isSameProjection]){
            transformedContentsBoundingBox = [transformedContentsBoundingBox transform:transform];
        }
        displayBoundingBox = [GPKGTileBoundingBoxUtils overlapWithBoundingBox:displayBoundingBox andBoundingBox:transformedContentsBoundingBox];
    }
    
    [self displayTilesWithOverlay:overlay andBoundingBox:displayBoundingBox andSrs:tileMatrixSetSrs andSpecifiedBoundingBox:nil];
}


-(void) displayTilesWithOverlay: (MKTileOverlay *) overlay andBoundingBox: (GPKGBoundingBox *) dataBoundingBox andSrs: (GPKGSpatialReferenceSystem *) srs andSpecifiedBoundingBox: (GPKGBoundingBox *) specifiedBoundingBox{
    
    GPKGBoundingBox * boundingBox = dataBoundingBox;
    if(boundingBox != nil){
        boundingBox = [self transformBoundingBoxToWgs84:boundingBox withSrs:srs];
    }else{
        boundingBox = [[GPKGBoundingBox alloc] initWithMinLongitudeDouble:-PROJ_WGS84_HALF_WORLD_LON_WIDTH andMinLatitudeDouble:PROJ_WEB_MERCATOR_MIN_LAT_RANGE andMaxLongitudeDouble:PROJ_WGS84_HALF_WORLD_LON_WIDTH andMaxLatitudeDouble:PROJ_WEB_MERCATOR_MAX_LAT_RANGE];
    }
    
    if(specifiedBoundingBox != nil){
        boundingBox = [GPKGTileBoundingBoxUtils overlapWithBoundingBox:boundingBox andBoundingBox:specifiedBoundingBox];
    }
    
    if(self.tilesBoundingBox == nil){
        self.tilesBoundingBox = boundingBox;
    }else{
        self.tilesBoundingBox = [GPKGTileBoundingBoxUtils unionWithBoundingBox:self.tilesBoundingBox andBoundingBox:boundingBox];
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.mapView addOverlay:overlay];
    });
}


-(GPKGBoundingBox *) transformBoundingBoxToWgs84: (GPKGBoundingBox *) boundingBox withSrs: (GPKGSpatialReferenceSystem *) srs{
    
    SFPProjection *projection = [srs projection];
    if([projection getUnit] == SFP_UNIT_DEGREES){
        boundingBox = [GPKGTileBoundingBoxUtils boundDegreesBoundingBoxWithWebMercatorLimits:boundingBox];
    }
    SFPProjectionTransform *transformToWebMercator = [[SFPProjectionTransform alloc] initWithFromProjection:projection andToEpsg:PROJ_EPSG_WEB_MERCATOR];
    GPKGBoundingBox *webMercatorBoundingBox = [boundingBox transform:transformToWebMercator];
    SFPProjectionTransform *transform = [[SFPProjectionTransform alloc] initWithFromEpsg:PROJ_EPSG_WEB_MERCATOR andToEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
    boundingBox = [webMercatorBoundingBox transform:transform];
    return boundingBox;
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
            
            GPKGFeatureIndexResults *indexResults = [indexer queryWithBoundingBox:mapViewBoundingBox andProjection:mapViewProjection];
            GPKGBoundingBox *complementary = [mapViewBoundingBox complementaryWgs84];
            if(complementary != nil){
                GPKGFeatureIndexResults *indexResults2 = [indexer queryWithBoundingBox:complementary andProjection:mapViewProjection];
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
                        
                        count = [self processFeatureRow:row withDatabase:database andCount:count andMaxFeatures:maxFeatures andEditable:editable andTableName:tableName andConverter:converter andFilterBoundingBox:filterBoundingBox andFilterMaxLongitude:filterMaxLongitude andFilter:filter];
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
            
            count = [self processFeatureRow:row withDatabase:database andCount:count andMaxFeatures:maxFeatures andEditable:editable andTableName:tableName andConverter:converter andFilterBoundingBox:nil andFilterMaxLongitude:0 andFilter:filter];
        }
    }
    @finally {
        [indexResults close];
    }
    
    return count;
}


-(int) processFeatureRow: (GPKGFeatureRow *) row withDatabase: (NSString *) database andCount: (int) count andMaxFeatures: (int) maxFeatures andEditable: (BOOL) editable andTableName: (NSString *) tableName andConverter: (GPKGMapShapeConverter *) converter andFilterBoundingBox: (GPKGBoundingBox *) filterBoundingBox andFilterMaxLongitude: (double) maxLongitude andFilter: (BOOL) filter{
    
    if(![self.featureShapes existsWithFeatureId:[row getId] inDatabase:database withTable:tableName]){
        count = [self processFeatureRowWithDatabase:database andTableName:tableName andConverter:converter andFeatureRow:row andCount:count andMaxFeatures:maxFeatures andEditable:editable andFilterBoundingBox:filterBoundingBox andFilterMaxLongitude:maxLongitude andFilter:filter];
    }
    
    return count;
}


-(int) processFeatureRowWithDatabase: (NSString *) database andTableName: (NSString *) tableName andConverter: (GPKGMapShapeConverter *) converter andFeatureRow: (GPKGFeatureRow *) row andCount: (int) count andMaxFeatures: (int) maxFeatures andEditable: (BOOL) editable andFilterBoundingBox: (GPKGBoundingBox *) boundingBox andFilterMaxLongitude: (double) maxLongitude andFilter: (BOOL) filter{
    
    GPKGGeometryData * geometryData = [row getGeometry];
    if(geometryData != nil && !geometryData.empty){
        
        SFGeometry * geometry = geometryData.geometry;
        
        if(geometry != nil){
            
            BOOL passesFilter = YES;
            
            if(filter && boundingBox != nil){
                SFGeometryEnvelope * envelope = geometryData.envelope;
                if(envelope == nil){
                    envelope = [SFGeometryEnvelopeBuilder buildEnvelopeWithGeometry:geometry];
                }
                if(envelope != nil){
                    if(geometry.geometryType == SF_POINT){
                        SFPoint *point = (SFPoint *) geometry;
                        passesFilter = [GPKGTileBoundingBoxUtils isPoint:point inBoundingBox:boundingBox withMaxLongitude:maxLongitude];
                    }else{
                        GPKGBoundingBox *geometryBoundingBox = [[GPKGBoundingBox alloc] initWithGeometryEnvelope:envelope];
                        passesFilter = [GPKGTileBoundingBoxUtils overlapWithBoundingBox:boundingBox andBoundingBox:geometryBoundingBox withMaxLongitude:maxLongitude] != nil;
                    }
                }
            }
            
            if(passesFilter && count++ < maxFeatures){
                NSNumber * featureId = [row getId];
                GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                [self updateFeaturesBoundingBox:shape];
                [self prepareShapeOptionsWithShape:shape andEditable:editable andTopLevel:true];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    GPKGMapShape * mapShape = [GPKGMapShapeConverter addMapShape:shape toMapView:self.mapView];
//                    if(self.editFeaturesMode){
//                        GPKGMapPoint *mapPoint = [self addEditableShapeWithFeatureId:featureId andShape:mapShape];
//                        if(mapPoint != nil){
//                            GPKGMapShape *mapPointShape = [[GPKGMapShape alloc] initWithGeometryType:SF_POINT andShapeType:GPKG_MST_POINT andShape:mapPoint];
//                            [self.featureShapes addMapShape:mapPointShape withFeatureId:featureId toDatabase:database withTable:tableName];
//                        }
//                    }else{
                        [self addMapPointShapeWithFeatureId:[featureId intValue] andDatabase:database andTableName:tableName andMapShape:mapShape];
                    //}
                    [self.featureShapes addMapShape:mapShape withFeatureId:featureId toDatabase:database withTable:tableName];
                });
            }
        }
        
    }
    return count;
}


-(void) prepareShapeOptionsWithShape: (GPKGMapShape *) shape andEditable: (BOOL) editable andTopLevel: (BOOL) topLevel{
    
    switch(shape.shapeType){
        case GPKG_MST_POINT:
        {
            GPKGMapPoint * mapPoint = (GPKGMapPoint *) shape.shape;
            [self setShapeOptionsWithMapPoint:mapPoint andEditable:editable andClickable:topLevel];
        }
            break;
            
        case GPKG_MST_MULTI_POINT:
        {
            GPKGMultiPoint * multiPoint = (GPKGMultiPoint *) shape.shape;
            for(GPKGMapPoint * mapPoint in multiPoint.points){
                [self setShapeOptionsWithMapPoint:mapPoint andEditable:editable andClickable:false];
            }
        }
            break;
            
        case GPKG_MST_COLLECTION:
        {
            NSArray * shapeArray = (NSArray *) shape.shape;
            for(GPKGMapShape * shape in shapeArray){
                [self prepareShapeOptionsWithShape:shape andEditable:editable andTopLevel:false];
            }
        }
            break;
            
        default:
            
            break;
    }
    
}


-(void) setShapeOptionsWithMapPoint: (GPKGMapPoint *) mapPoint andEditable: (BOOL) editable andClickable: (BOOL) clickable{
    
    if(editable){
        if(clickable){
            [mapPoint.options setPinTintColor:[UIColor greenColor]];
        }else{
            [mapPoint.options setPinTintColor:[UIColor purpleColor]];
        }
    }else{
        [mapPoint.options setPinTintColor:[UIColor purpleColor]];
    }
    
}


-(void) addMapPointShapeWithFeatureId: (int) featureId andDatabase: (NSString *) database andTableName: (NSString *) tableName andMapShape: (GPKGMapShape *) shape
{
    if(shape.shapeType == GPKG_MST_POINT){
        GPKGMapPoint * mapPoint = (GPKGMapPoint *) shape.shape;
        GPKGSMapPointData * data = [self getOrCreateDataWithMapPoint:mapPoint];
        data.type = GPKGS_MPDT_POINT;
        data.database = database;
        data.tableName = tableName;
        data.featureId = featureId;
        [self setTitleWithGeometryType:shape.geometryType andMapPoint:mapPoint];
    }
    
}


-(GPKGSMapPointData *) getOrCreateDataWithMapPoint: (GPKGMapPoint *) mapPoint{
    if(mapPoint.data == nil){
        mapPoint.data = [[GPKGSMapPointData alloc] init];
    }
    return (GPKGSMapPointData *) mapPoint.data;
}


-(void) updateFeaturesBoundingBox: (GPKGMapShape *) shape
{
    if(self.featuresBoundingBox != nil){
        [shape expandBoundingBox:self.featuresBoundingBox];
    }else{
        self.featuresBoundingBox = [shape boundingBox];
    }
}


-(NSString *) buildLocationTitleWithMapPoint: (GPKGMapPoint *) mapPoint{
    
    CLLocationCoordinate2D coordinate = mapPoint.coordinate;
    
    NSString *lat = [self.locationDecimalFormatter stringFromNumber:[NSNumber numberWithDouble:coordinate.latitude]];
    NSString *lon = [self.locationDecimalFormatter stringFromNumber:[NSNumber numberWithDouble:coordinate.longitude]];
    
    NSString * title = [NSString stringWithFormat:@"(lat=%@, lon=%@)", lat, lon];
    
    return title;
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
