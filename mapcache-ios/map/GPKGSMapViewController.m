//
//  GPKGSMapViewController.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/13/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSMapViewController.h"
#import <objc/runtime.h>
#import "GPKGGeoPackageManager.h"
#import "GPKGSDatabases.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGSTileTable.h"
#import "GPKGOverlayFactory.h"
#import "GPKGProjectionTransform.h"
#import "GPKGProjectionConstants.h"
#import "GPKGProjectionFactory.h"
#import "GPKGTileBoundingBoxUtils.h"
#import "GPKGSFeatureOverlayTable.h"
#import "GPKGMapShapeConverter.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGFeatureTiles.h"
#import "GPKGFeatureIndexer.h"
#import "GPKGFeatureOverlay.h"
#import "GPKGSUtils.h"
#import "GPKGSDownloadTilesViewController.h"
#import "GPKGSCreateTilesData.h"
#import "GPKGSSelectFeatureTableViewController.h"
#import "GPKGSCreateFeatureTilesViewController.h"
#import "GPKGSMapPointData.h"
#import "GPKGSEditTypes.h"
#import "GPKGSDisplayTextViewController.h"
#import "WKBGeometryPrinter.h"
#import "GPKGShapePoints.h"
#import "GPKGShapeWithChildrenPoints.h"
#import "GPGKSMapPointInitializer.h"

NSString * const GPKGS_MAP_SEG_DOWNLOAD_TILES = @"downloadTiles";
NSString * const GPKGS_MAP_SEG_SELECT_FEATURE_TABLE = @"selectFeatureTable";
NSString * const GPKGS_MAP_SEG_FEATURE_TILES_REQUEST = @"featureTiles";
NSString * const GPKGS_MAP_SEG_EDIT_FEATURES_REQUEST = @"editFeatures";
NSString * const GPKGS_MAP_SEG_CREATE_FEATURE_TILES = @"createFeatureTiles";
NSString * const GPKGS_MAP_SEG_DISPLAY_TEXT = @"displayText";

const char MapConstantKey;

@interface GPKGSMapViewController ()

@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGSDatabases *active;
@property (nonatomic, strong) NSMutableDictionary * geoPackages;
@property (nonatomic, strong) GPKGBoundingBox * featuresBoundingBox;
@property (nonatomic, strong) GPKGBoundingBox * tilesBoundingBox;
@property (nonatomic) BOOL featureOverlayTiles;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (nonatomic, strong) NSUserDefaults * settings;
@property (atomic) int updateCountId;
@property (nonatomic) BOOL boundingBoxMode;
@property (nonatomic) BOOL editFeaturesMode;
@property (nonatomic) CLLocationCoordinate2D boundingBoxStartCorner;
@property (nonatomic) CLLocationCoordinate2D boundingBoxEndCorner;
@property (nonatomic, strong) MKPolygon * boundingBox;
@property (nonatomic) BOOL drawing;
@property (nonatomic, strong) NSString * editFeaturesDatabase;
@property (nonatomic, strong) NSString * editFeaturesTable;
@property (nonatomic, strong) NSMutableDictionary * editFeatureIds;
@property (nonatomic, strong) NSMutableDictionary * editFeatureObjects;
@property (nonatomic) enum GPKGSEditType editFeatureType;
@property (nonatomic, strong) NSMutableArray * editPoints;
@property (nonatomic, strong) NSMutableArray * editHolePoints;
@property (nonatomic, strong) GPKGMapPoint * editFeatureMapPoint;
@property (nonatomic, strong) GPKGMapPoint * tempEditFeatureMapPoint;
@property (nonatomic, strong) GPKGMapShapePoints * editFeatureShape;
@property (nonatomic, strong) NSObject <GPKGShapePoints> * editFeatureShapePoints;
@property (nonatomic, strong) MKPolyline * editLinestring;
@property (nonatomic, strong) MKPolygon * editPolygon;
@property (nonatomic, strong) MKPolygon * editHolePolygon;
@property (nonatomic, strong) NSMutableArray * holePolygons;
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
@property (nonatomic, strong) UIColor * drawPolygonHoleColor;
@property (nonatomic) double drawPolygonHoleLineWidth;
@property (nonatomic, strong) UIColor * drawPolygonHoleFillColor;
@property (nonatomic) BOOL internalSeg;
@property (nonatomic, strong) NSString * segRequest;
@property (nonatomic, strong) GPKGMapPoint * selectedMapPoint;
@property (nonatomic, strong) NSNumberFormatter *locationDecimalFormatter;

@end

@implementation GPKGSMapViewController

#define TAG_MAP_TYPE 1
#define TAG_MAX_FEATURES 2
#define TAG_EXISTING_FEATURE 3
#define TAG_DELETE_EXISTING_FEATURE 4
#define TAG_CLEAR_EDIT_FEATURES 5
#define TAG_DELETE_EDIT_POINT 6
#define TAG_EDIT_FEATURE_SHAPE 7

static NSString *mapPointImageReuseIdentifier = @"mapPointImageReuseIdentifier";
static NSString *mapPointPinReuseIdentifier = @"mapPointPinReuseIdentifier";

- (void)viewDidLoad {
    [super viewDidLoad];
    self.updateCountId = 0;
    self.settings = [NSUserDefaults standardUserDefaults];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    self.manager = [GPKGGeoPackageFactory getManager];
    self.active = [GPKGSDatabases getInstance];
    self.geoPackages = [[NSMutableDictionary alloc] init];
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager setDelegate:self];
    [self.locationManager requestWhenInUseAuthorization];
    self.editFeatureIds = [[NSMutableDictionary alloc] init];
    self.editFeatureObjects = [[NSMutableDictionary alloc] init];
    self.editFeatureType = GPKGS_ET_NONE;
    self.editPoints = [[NSMutableArray alloc] init];
    self.editHolePoints = [[NSMutableArray alloc] init];
    self.holePolygons = [[NSMutableArray alloc] init];
    [self resetBoundingBox];
    [self resetEditFeatures];
    [self.mapView addGestureRecognizer:[[UILongPressGestureRecognizer alloc]
                                        initWithTarget:self action:@selector(longPressGesture:)]];
    self.boundingBoxStartCorner = kCLLocationCoordinate2DInvalid;
    self.boundingBoxEndCorner = kCLLocationCoordinate2DInvalid;
    
    self.boundingBoxColor = [GPKGSUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_BOUNDING_BOX_DRAW_COLOR]];
    self.boundingBoxLineWidth = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_BOUNDING_BOX_DRAW_LINE_WIDTH] doubleValue];
    if([GPKGSProperties getBoolOfProperty:GPKGS_PROP_BOUNDING_BOX_DRAW_FILL]){
        self.boundingBoxFillColor = [GPKGSUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_BOUNDING_BOX_DRAW_FILL_COLOR]];
    }
    
    self.defaultPolylineColor = [GPKGSUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_DEFAULT_POLYLINE_COLOR]];
    self.defaultPolylineLineWidth = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_DEFAULT_POLYLINE_LINE_WIDTH] doubleValue];

    self.defaultPolygonColor = [GPKGSUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_DEFAULT_POLYGON_COLOR]];
    self.defaultPolygonLineWidth = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_DEFAULT_POLYGON_LINE_WIDTH] doubleValue];
    if([GPKGSProperties getBoolOfProperty:GPKGS_PROP_DEFAULT_POLYGON_FILL]){
        self.defaultPolygonFillColor = [GPKGSUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_DEFAULT_POLYGON_FILL_COLOR]];
    }
    
    self.editPolylineColor = [GPKGSUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_EDIT_POLYLINE_COLOR]];
    self.editPolylineLineWidth = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_EDIT_POLYLINE_LINE_WIDTH] doubleValue];
    
    self.editPolygonColor = [GPKGSUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_EDIT_POLYGON_COLOR]];
    self.editPolygonLineWidth = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_EDIT_POLYGON_LINE_WIDTH] doubleValue];
    if([GPKGSProperties getBoolOfProperty:GPKGS_PROP_EDIT_POLYGON_FILL]){
        self.editPolygonFillColor = [GPKGSUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_EDIT_POLYGON_FILL_COLOR]];
    }
    
    self.drawPolylineColor = [GPKGSUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_DRAW_POLYLINE_COLOR]];
    self.drawPolylineLineWidth = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_DRAW_POLYLINE_LINE_WIDTH] doubleValue];
    
    self.drawPolygonColor = [GPKGSUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_DRAW_POLYGON_COLOR]];
    self.drawPolygonLineWidth = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_DRAW_POLYGON_LINE_WIDTH] doubleValue];
    if([GPKGSProperties getBoolOfProperty:GPKGS_PROP_DRAW_POLYGON_FILL]){
        self.drawPolygonFillColor = [GPKGSUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_DRAW_POLYGON_FILL_COLOR]];
    }
    
    self.drawPolygonHoleColor = [GPKGSUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_DRAW_POLYGON_HOLE_COLOR]];
    self.drawPolygonHoleLineWidth = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_DRAW_POLYGON_HOLE_LINE_WIDTH] doubleValue];
    if([GPKGSProperties getBoolOfProperty:GPKGS_PROP_DRAW_POLYGON_HOLE_FILL]){
        self.drawPolygonHoleFillColor = [GPKGSUtils getColor:[GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_DRAW_POLYGON_HOLE_FILL_COLOR]];
    }
    
    self.locationDecimalFormatter = [[NSNumberFormatter alloc] init];
    self.locationDecimalFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    self.locationDecimalFormatter.maximumFractionDigits = 4;
    
    [self.active setModified:true];
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    if(self.internalSeg){
        self.internalSeg = false;
    }else{
        if(self.active.modified){
            [self.active setModified:false];
            [self resetBoundingBox];
            [self resetEditFeatures];
            [self updateInBackgroundWithZoom:true];
        }
    }
}

- (MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id)overlay {
    MKOverlayRenderer * rendered = nil;
    if ([overlay isKindOfClass:[MKPolygon class]]) {
        MKPolygonRenderer * polygonRenderer = [[MKPolygonRenderer alloc] initWithPolygon:overlay];
        if(self.drawing || (self.boundingBox != nil && self.boundingBox == overlay)){
            polygonRenderer.strokeColor = self.boundingBoxColor;
            polygonRenderer.lineWidth = self.boundingBoxLineWidth;
            if(self.boundingBoxFillColor != nil){
                polygonRenderer.fillColor = self.boundingBoxFillColor;
            }
        }else if(self.editFeaturesMode){
            polygonRenderer.strokeColor = self.editPolygonColor;
            polygonRenderer.lineWidth = self.editPolygonLineWidth;
            if(self.editPolygonFillColor != nil){
                polygonRenderer.fillColor = self.editPolygonFillColor;
            }
        }else{
            polygonRenderer.strokeColor = self.defaultPolygonColor;
            polygonRenderer.lineWidth = self.defaultPolygonLineWidth;
            if(self.defaultPolygonFillColor != nil){
                polygonRenderer.fillColor = self.defaultPolygonFillColor;
            }
        }
        rendered = polygonRenderer;
    }else if ([overlay isKindOfClass:[MKPolyline class]]) {
        MKPolylineRenderer * polylineRenderer = [[MKPolylineRenderer alloc] initWithPolyline:overlay];
        if(self.editFeaturesMode){
            polylineRenderer.strokeColor = self.editPolylineColor;
            polylineRenderer.lineWidth = self.editPolylineLineWidth;
        }else{
            polylineRenderer.strokeColor = self.defaultPolylineColor;
            polylineRenderer.lineWidth = self.defaultPolylineLineWidth;
        }
        rendered = polylineRenderer;
    }else if ([overlay isKindOfClass:[MKTileOverlay class]]) {
        rendered = [[MKTileOverlayRenderer alloc] initWithTileOverlay:overlay];
    }
    return rendered;
}

- (MKAnnotationView *) mapView:(MKMapView *)mapView viewForAnnotation:(id <MKAnnotation>) annotation
{
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
            mapPointPinView.pinColor = mapPoint.options.pinColor;
            view = mapPointPinView;
        }
        
        if(mapPoint.title == nil){
            [self setTitleWithMapPoint:mapPoint];
        }
        
        UIButton *optionsButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
        [optionsButton addTarget:self action:@selector(selectedMapPointOptions:) forControlEvents:UIControlEventTouchUpInside];
        
        view.rightCalloutAccessoryView = optionsButton;
        view.canShowCallout = YES;
        
        view.draggable = mapPoint.options.draggable;
    }
    return view;
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch(alertView.tag){
        case TAG_MAP_TYPE:
            [self handleMapTypeWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
        case TAG_MAX_FEATURES:
            [self handleMaxFeaturesWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
        case TAG_EXISTING_FEATURE:
            [self handleEditExistingFeatureWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
        case TAG_DELETE_EXISTING_FEATURE:
            [self handleDeleteExistingFeatureWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
        case TAG_CLEAR_EDIT_FEATURES:
            [self handleClearEditFeaturesWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
        case TAG_DELETE_EDIT_POINT:
            [self handleDeleteEditPointWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
        case TAG_EDIT_FEATURE_SHAPE:
            [self handleEditFeatureShapeWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
    }
}

- (IBAction) selectedMapPointOptions:(id)sender {
    
    if(self.selectedMapPoint != nil){
        GPKGSMapPointData * data = [self getOrCreateDataWithMapPoint:self.selectedMapPoint];
        switch(data.type){
            case GPKGS_MPDT_EDIT_FEATURE_POINT:
                [self editFeatureShapeClickWithMapPoint:self.selectedMapPoint];
                break;
            case GPKGS_MPDT_EDIT_FEATURE:
                // Handle clicks on an existing feature in edit mode
                [self editExistingFeatureClickWithMapPoint:self.selectedMapPoint];
                break;
            case GPKGS_MPDT_NEW_EDIT_POINT:
            case GPKGS_MPDT_NEW_EDIT_HOLE_POINT:
                [self editPointClickWithMapPoint:self.selectedMapPoint];
                break;
            case GPKGS_MPDT_POINT:
            case GPKGS_MPDT_NONE:
                // Handle clicks on normal map points or points within geometries
                [self performSegueWithIdentifier:GPKGS_MAP_SEG_DISPLAY_TEXT sender:self.selectedMapPoint];
                break;
            default:
                break;
        }
    }
    
}

-(void) editFeatureShapeClickWithMapPoint: (GPKGMapPoint *) mapPoint{
    
    NSObject<GPKGShapePoints> * shapePoints = [self.editFeatureShape getShapePointsForPoint:mapPoint];
    
    if(shapePoints != nil){
        
        NSMutableArray * options = [[NSMutableArray alloc] init];
        [options addObject:[GPKGSProperties getValueOfProperty:GPKGS_PROP_EDIT_FEATURES_SHAPE_POINT_DELETE_LABEL]];
        [options addObject:[GPKGSProperties getValueOfProperty:GPKGS_PROP_EDIT_FEATURES_SHAPE_ADD_POINTS_LABEL]];
        
        if([[shapePoints class] conformsToProtocol:@protocol(GPKGShapeWithChildrenPoints)]){
            [options addObject:[GPKGSProperties getValueOfProperty:GPKGS_PROP_EDIT_FEATURES_SHAPE_ADD_HOLE_LABEL]];
        }

        UIAlertView *alert = [[UIAlertView alloc]
                              initWithTitle:[self getTitleAndSubtitleWithMapPoint:mapPoint andDelimiter:@"\n"]
                              message:nil
                              delegate:self
                              cancelButtonTitle:nil
                              otherButtonTitles:nil];
        
        for (NSString *option in options) {
            [alert addButtonWithTitle:option];
        }
        alert.cancelButtonIndex = [alert addButtonWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]];
        
        alert.tag = TAG_EDIT_FEATURE_SHAPE;
        
        objc_setAssociatedObject(alert, &MapConstantKey, mapPoint, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        
        [alert show];
    }
}

- (void) handleEditFeatureShapeWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    // TODO
}

-(void) editExistingFeatureClickWithMapPoint: (GPKGMapPoint *) mapPoint{
    
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:[self getTitleAndSubtitleWithMapPoint:mapPoint andDelimiter:@"\n"]
                          message:nil
                          delegate:self
                          cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                          otherButtonTitles:[GPKGSProperties getValueOfProperty:GPKGS_PROP_EDIT_FEATURES_INFO_LABEL],
                          [GPKGSProperties getValueOfProperty:GPKGS_PROP_EDIT_FEATURES_EDIT_LABEL],
                          [GPKGSProperties getValueOfProperty:GPKGS_PROP_EDIT_FEATURES_DELETE_LABEL],
                          nil];
    
    alert.tag = TAG_EXISTING_FEATURE;
    
    objc_setAssociatedObject(alert, &MapConstantKey, mapPoint, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [alert show];
}

- (void) handleEditExistingFeatureWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if(buttonIndex > 0){
    
        GPKGMapPoint *mapPoint = objc_getAssociatedObject(alertView, &MapConstantKey);
        
        switch(buttonIndex){
            case 1:
                [self performSegueWithIdentifier:GPKGS_MAP_SEG_DISPLAY_TEXT sender:mapPoint];
                break;
            case 2:
                self.tempEditFeatureMapPoint = mapPoint;
                [self validateAndClearEditFeaturesForType:GPKGS_ET_EDIT_FEATURE];
                break;
            case 3:
                [self deleteExistingFeatureOptionWithMapPoint:mapPoint];
                break;
        }
    
    }
}

-(void) deleteExistingFeatureOptionWithMapPoint: (GPKGMapPoint *) mapPoint{
    
    UIAlertView * alert = [[UIAlertView alloc]
                           initWithTitle:[NSString stringWithFormat:@"%@ %@", [GPKGSProperties getValueOfProperty:GPKGS_PROP_EDIT_FEATURES_DELETE_LABEL], [self getTitleAndSubtitleWithMapPoint:mapPoint andDelimiter:@" "]]
                           message:[NSString stringWithFormat:@"%@ %@ from %@ - %@ %@ ?", [GPKGSProperties getValueOfProperty:GPKGS_PROP_EDIT_FEATURES_DELETE_LABEL], mapPoint.title, self.editFeaturesDatabase, self.editFeaturesTable, mapPoint.subtitle]
                           delegate:self
                           cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                           otherButtonTitles:[GPKGSProperties getValueOfProperty:GPKGS_PROP_EDIT_FEATURES_DELETE_LABEL],
                           nil];
    objc_setAssociatedObject(alert, &MapConstantKey, mapPoint, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    alert.tag = TAG_DELETE_EXISTING_FEATURE;
    [alert show];
    
}

- (void) handleDeleteExistingFeatureWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if(buttonIndex > 0){
    
        GPKGMapPoint *mapPoint = objc_getAssociatedObject(alertView, &MapConstantKey);
        
        GPKGGeoPackage * geoPackage = [self.manager open:self.editFeaturesDatabase];
        @try {

            GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:self.editFeaturesTable];
        
            NSNumber * mapPointId = [mapPoint getIdAsNumber];
            NSNumber * featureId = [self.editFeatureIds objectForKey:mapPointId];
            if(featureId != nil){
                GPKGFeatureRow * featureRow = (GPKGFeatureRow *)[featureDao queryForIdObject:featureId];
            
                if(featureRow != nil){
                    [featureDao delete:featureRow];
                    [self.mapView removeAnnotation:mapPoint];
                    [self.editFeatureIds removeObjectForKey:mapPointId];
                    GPKGMapShape * featureObject = [self.editFeatureObjects objectForKey:mapPointId];
                    if(featureObject != nil){
                        [self.editFeatureObjects removeObjectForKey:mapPointId];
                        [featureObject removeFromMapView:self.mapView];
                    }
                    [self updateLastChangeWithGeoPackage:geoPackage andFeatureDao:featureDao];
                    
                    [self.active setModified:true];
                }
            }
            
        }
        @catch (NSException *e) {
            [GPKGSUtils showMessageWithDelegate:self
                                       andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_EDIT_FEATURES_DELETE_LABEL]
                                     andMessage:[NSString stringWithFormat:@"%@", [e description]]];
        }
        @finally {
            [geoPackage close];
        }
    }
}

-(void) updateLastChangeWithGeoPackage: (GPKGGeoPackage *) geoPackage andFeatureDao: (GPKGFeatureDao *) featureDao{
    @try {
        GPKGGeometryColumnsDao * geometryColumnsDao = [geoPackage getGeometryColumnsDao];
        GPKGContents * contents = [geometryColumnsDao getContents:featureDao.geometryColumns];
        [contents setLastChange:[NSDate date]];
        GPKGContentsDao * contentsDao = [geoPackage getContentsDao];
        [contentsDao update:contents];
    }
    @catch (NSException *e) {
        NSLog(@"Failed to update contents last change date. GeoPackage: %@, Table: %@, Error:%@", geoPackage.name, featureDao.tableName, [e description]);
    }
}

-(void) editPointClickWithMapPoint: (GPKGMapPoint *) mapPoint{
    
    UIAlertView * alert = [[UIAlertView alloc]
                           initWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_EDIT_FEATURES_DELETE_LABEL]
                           message:[NSString stringWithFormat:@"%@ %@ ?", [GPKGSProperties getValueOfProperty:GPKGS_PROP_EDIT_FEATURES_DELETE_LABEL], [self getTitleAndSubtitleWithMapPoint:mapPoint andDelimiter:@" "]]
                           delegate:self
                           cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                           otherButtonTitles:[GPKGSProperties getValueOfProperty:GPKGS_PROP_EDIT_FEATURES_DELETE_LABEL],
                           nil];
    objc_setAssociatedObject(alert, &MapConstantKey, mapPoint, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    alert.tag = TAG_DELETE_EDIT_POINT;
    [alert show];
}

-(void) handleDeleteEditPointWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if(buttonIndex > 0){
    
        GPKGMapPoint *mapPoint = objc_getAssociatedObject(alertView, &MapConstantKey);
        
        NSMutableArray * points = nil;
        
        GPKGSMapPointData * data = [self getOrCreateDataWithMapPoint:mapPoint];
        switch(data.type){
            case GPKGS_MPDT_NEW_EDIT_POINT:
                points = self.editPoints;
                break;
            case GPKGS_MPDT_NEW_EDIT_HOLE_POINT:
                points = self.editHolePoints;
                break;
            default:
                break;
        }
        
        if(points != nil){
            
            [points removeObject:mapPoint];
            [self.mapView removeAnnotation:mapPoint];
            
            [self updateEditState:true];
        }
    }
}

- (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view didChangeDragState:(MKAnnotationViewDragState)newState fromOldState:(MKAnnotationViewDragState)oldState {
    if ([view.annotation isKindOfClass:[GPKGMapPoint class]]) {
        if (newState == MKAnnotationViewDragStateEnding) {
            view.dragState = MKAnnotationViewDragStateNone;
        }
        GPKGMapPoint * mapPoint = (GPKGMapPoint *) view.annotation;
        [self updateTitleWithMapPoint:mapPoint];
        [self updateEditState:false];
    }
}

- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view{
    
    if ([view.annotation isKindOfClass:[GPKGMapPoint class]]) {
        self.selectedMapPoint = (GPKGMapPoint *) view.annotation;
    }
    
}

-(void) longPressGesture:(UILongPressGestureRecognizer *) longPressGestureRecognizer{
    
    CGPoint cgPoint = [longPressGestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D point = [self.mapView convertPoint:cgPoint toCoordinateFromView:self.mapView];
    
    if(self.boundingBoxMode){
    
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
                [self.boundingBoxClearButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_BOUNDING_BOX_CLEAR_ACTIVE_IMAGE] forState:UIControlStateNormal];
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
                    [self updateEditState:true];
                }
            }else{
                GPKGMapPoint * mapPoint = [self addEditPoint:point];
                GPKGSMapPointData * data = [self getOrCreateDataWithMapPoint:mapPoint];
                if(self.editFeatureType == GPKGS_ET_POLYGON_HOLE){
                    [self.editHolePoints addObject:mapPoint];
                    data.type = GPKGS_MPDT_NEW_EDIT_HOLE_POINT;
                }else{
                    [self.editPoints addObject:mapPoint];
                    data.type = GPKGS_MPDT_NEW_EDIT_POINT;
                }
                [self setTitleWithTitle:[GPKGSEditTypes pointName:self.editFeatureType] andMapPoint:mapPoint];
                [self updateEditState:true];
            }
        }
    }
}

-(GPKGMapPoint *) addEditPoint: (CLLocationCoordinate2D) point{
    GPKGMapPoint * mapPoint = [[GPKGMapPoint alloc] initWithLocation:point];
    mapPoint.options.draggable = true;

    switch(self.editFeatureType){
        case GPKGS_ET_POINT:
            [mapPoint.options setPinColor:MKPinAnnotationColorRed];
            break;
        case GPKGS_ET_LINESTRING:
        case GPKGS_ET_POLYGON:
            [mapPoint.options setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_POINT_IMAGE]];
            [mapPoint.options setPinColor:MKPinAnnotationColorGreen];
            break;
        case GPKGS_ET_POLYGON_HOLE:
            [mapPoint.options setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_HOLE_POINT_IMAGE]];
            break;
        case GPKGS_ET_EDIT_FEATURE:
            if([self.editFeatureShapePoints isKindOfClass:[GPKGPolygonHolePoints class]]){
                [mapPoint.options setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_HOLE_POINT_IMAGE]];
            }else{
                [mapPoint.options setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_POINT_IMAGE]];
            }
            break;
        default:
            break;
    }
    [self.mapView addAnnotation:mapPoint];
    return mapPoint;
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

- (IBAction)zoomToActiveButton:(id)sender {
    [self zoomToActive];
}

- (IBAction)featuresButton:(id)sender {
    if(!self.editFeaturesMode){
        self.segRequest = GPKGS_MAP_SEG_EDIT_FEATURES_REQUEST;
        [self performSegueWithIdentifier:GPKGS_MAP_SEG_SELECT_FEATURE_TABLE sender:self];
    }else{
        [self resetEditFeatures];
        [self updateInBackgroundWithZoom:false];
    }
}

- (IBAction)boundingBoxButton:(id)sender {
    if(!self.boundingBoxMode){
        
        if(self.editFeaturesMode){
            [self resetEditFeatures];
            [self updateInBackgroundWithZoom:false];
        }
        
        self.boundingBoxMode = true;
        [self setBoundingBoxButtonsHidden:false];
        
    }else{
        [self resetBoundingBox];
    }
}

- (IBAction)downloadTilesButton:(id)sender {
    [self performSegueWithIdentifier:GPKGS_MAP_SEG_DOWNLOAD_TILES sender:self];
}

- (IBAction)featureTilesButton:(id)sender {
    self.segRequest = GPKGS_MAP_SEG_FEATURE_TILES_REQUEST;
    [self performSegueWithIdentifier:GPKGS_MAP_SEG_SELECT_FEATURE_TABLE sender:self];
}

- (IBAction)boundingBoxClearButton:(id)sender {
    [self clearBoundingBox];
}

- (IBAction)editPointButton:(id)sender {
    [self validateAndClearEditFeaturesForType:GPKGS_ET_POINT];
}

- (IBAction)editLinestringButton:(id)sender {
    [self validateAndClearEditFeaturesForType:GPKGS_ET_LINESTRING];
}

- (IBAction)editPolygonButton:(id)sender {
    [self validateAndClearEditFeaturesForType:GPKGS_ET_POLYGON];
}

- (IBAction)editAcceptButton:(id)sender {
    if(self.editFeatureType != GPKGS_ET_NONE && ([self.editPoints count] > 0 || self.editFeatureType == GPKGS_ET_EDIT_FEATURE)){
        BOOL accept = false;
        switch(self.editFeatureType){
            case GPKGS_ET_POINT:
                accept = true;
                break;
            case GPKGS_ET_LINESTRING:
                if([self.editPoints count] >= 2){
                    accept = true;
                }
                break;
            case GPKGS_ET_POLYGON:
            case GPKGS_ET_POLYGON_HOLE:
                if([self.editPoints count] >= 3 && [self.editHolePoints count] == 0){
                    accept = true;
                }
                break;
            case GPKGS_ET_EDIT_FEATURE:
                accept = self.editFeatureShape != nil && [self.editFeatureShape isValid];
                break;
            default:
                break;
        }
        if(accept){
            [self saveEditFeatures];
        }
    }
}

- (IBAction)editClearButton:(id)sender {
    if([self.editPoints count] > 0 || self.editFeatureType == GPKGS_ET_EDIT_FEATURE){
        if(self.editFeatureType == GPKGS_ET_EDIT_FEATURE){
            self.editFeatureType = GPKGS_ET_NONE;
        }
        [self clearEditFeaturesAndPreserveType];
    }
}
- (IBAction)editPolygonHolesButton:(id)sender {
    if(self.editFeatureType != GPKGS_ET_POLYGON_HOLE){
        self.editFeatureType = GPKGS_ET_POLYGON_HOLE;
        [self.drawPolygonHoleButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_DRAW_POLYGON_HOLE_ACTIVE_IMAGE] forState:UIControlStateNormal];
    } else{
        self.editFeatureType = GPKGS_ET_POLYGON;
        [self.drawPolygonHoleButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_DRAW_POLYGON_HOLE_IMAGE] forState:UIControlStateNormal];
    }
}

- (IBAction)editAcceptPolygonHolesButton:(id)sender {
    if([self.editHolePoints count] >= 3){
        NSArray * locationPoints = [self getLocationPoints:self.editHolePoints];
        [self.holePolygons addObject:locationPoints];
        [self clearEditHoleFeatures];
        [self updateEditState:true];
    }
}

- (IBAction)editClearPolygonHolesButton:(id)sender {
    [self clearEditHoleFeatures];
    [self updateEditState:true];
}

-(NSArray *) getLocationPoints: (NSArray *) pointArray{
    NSMutableArray * points = [[NSMutableArray alloc] init];
    for(GPKGMapPoint * editPoint in pointArray){
        CLLocation * location = [[CLLocation alloc] initWithLatitude:editPoint.coordinate.latitude longitude:editPoint.coordinate.longitude];
        [points addObject:location];
    }
    return points;
}

-(void) validateAndClearEditFeaturesForType: (enum GPKGSEditType) editTypeClicked{
    
    if([self.editPoints count] == 0 && self.editFeatureType != GPKGS_ET_EDIT_FEATURE){
        [self clearEditFeaturesAndUpdateType:editTypeClicked];
    }else{
        UIAlertView * alert = [[UIAlertView alloc]
                               initWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_EDIT_FEATURES_CLEAR_VALIDATION_LABEL]
                               message:[GPKGSProperties getValueOfProperty:GPKGS_PROP_EDIT_FEATURES_CLEAR_VALIDATION_MESSAGE]
                               delegate:self
                               cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                               otherButtonTitles:[GPKGSProperties getValueOfProperty:GPKGS_PROP_OK_LABEL],
                               nil];
        objc_setAssociatedObject(alert, &MapConstantKey, [NSNumber numberWithInt:editTypeClicked], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        alert.tag = TAG_CLEAR_EDIT_FEATURES;
        [alert show];
    }
    
}

- (void) handleClearEditFeaturesWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex > 0){
        NSNumber *editTypeClicked = objc_getAssociatedObject(alertView, &MapConstantKey);
        if (self.editFeatureType == GPKGS_ET_EDIT_FEATURE) {
            self.editFeatureType = GPKGS_ET_NONE;
        }
        [self clearEditFeaturesAndUpdateType:(enum GPKGSEditType)editTypeClicked];
    }
}

-(void) clearEditFeaturesAndUpdateType: (enum GPKGSEditType) editType{
    enum GPKGSEditType previousType = self.editFeatureType;
    [self clearEditFeatures];
    [self setEditTypeWithPrevious:previousType andNew:editType];
}

-(void) clearEditFeaturesAndPreserveType{
    enum GPKGSEditType previousType = self.editFeatureType;
    [self clearEditFeatures];
    [self setEditTypeWithPrevious:GPKGS_ET_NONE andNew:previousType];
}

-(void) setEditTypeWithPrevious: (enum GPKGSEditType) previousType andNew: (enum GPKGSEditType) editType{
    
    if(editType != GPKGS_ET_NONE && previousType != editType){
        
        self.editFeatureType = editType;
        switch(editType){
            case GPKGS_ET_POINT:
                [self.drawPointButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_DRAW_POINT_ACTIVE_IMAGE] forState:UIControlStateNormal];
                break;
            case GPKGS_ET_LINESTRING:
                [self.drawLineButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_DRAW_LINE_ACTIVE_IMAGE] forState:UIControlStateNormal];
                break;
            case GPKGS_ET_POLYGON_HOLE:
                self.editFeatureType = GPKGS_ET_POLYGON;
            case GPKGS_ET_POLYGON:
                [self.drawPolygonButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_DRAW_POLYGON_ACTIVE_IMAGE] forState:UIControlStateNormal];
                [self setEditPolygonHoleButtonsHidden:false];
                break;
            case GPKGS_ET_EDIT_FEATURE:
                {
                    self.editFeatureMapPoint = self.tempEditFeatureMapPoint;
                    self.tempEditFeatureMapPoint = nil;
                    NSNumber * featureId = [self.editFeatureIds objectForKey:[self.editFeatureMapPoint getIdAsNumber]];
                    GPKGGeoPackage * geoPackage = [self.manager open:self.editFeaturesDatabase];
                    @try {
                        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:self.editFeaturesTable];
                        GPKGFeatureRow * featureRow = (GPKGFeatureRow *)[featureDao queryForIdObject:featureId];
                        WKBGeometry * geometry = [featureRow getGeometry].geometry;
                        GPKGMapShapeConverter * converter = [[GPKGMapShapeConverter alloc] initWithProjection:featureDao.projection];
                        GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                        
                        [self.mapView removeAnnotation:self.editFeatureMapPoint];
                        GPKGMapShape * featureObject = [self.editFeatureObjects objectForKey:[self.editFeatureMapPoint getIdAsNumber]];
                        if(featureObject != nil){
                            [self.editFeatureObjects removeObjectForKey:[self.editFeatureMapPoint getIdAsNumber]];
                            [featureObject removeFromMapView:self.mapView];
                        }
                        
                        self.editFeatureShape = [converter addMapShape:shape asPointsToMapView:self.mapView withPointOptions:[self getEditFeaturePointOptions] andPolylinePointOptions:[self getEditFeatureShapePointOptions] andPolygonPointOptions:[self getEditFeatureShapePointOptions] andPolygonPointHoleOptions:[self getEditFeatureShapeHolePointOptions]];
                        [self updateEditState:true];
                    }
                    @finally {
                        [geoPackage close];
                    }
                }
                break;
             default:
                break;
        }
    }
    
}

-(void) addEditableShapeBack{
    
    NSNumber * featureId = [self.editFeatureIds objectForKey:[self.editFeatureMapPoint getIdAsNumber]];
    GPKGGeoPackage * geoPackage = [self.manager open:self.editFeaturesDatabase];
    @try {
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:self.editFeaturesTable];
        GPKGFeatureRow * featureRow = (GPKGFeatureRow *) [featureDao queryForIdObject:featureId];
        GPKGGeometryData * geomData = [featureRow getGeometry];
        if(geomData != nil){
            WKBGeometry * geometry = geomData.geometry;
            if(geometry != nil){
                GPKGMapShapeConverter * converter = [[GPKGMapShapeConverter alloc] initWithProjection:featureDao.projection];
                GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                [self prepareShapeOptionsWithShape:shape andEditable:true andTopLevel:true];
                GPKGMapShape * mapShape = [GPKGMapShapeConverter addMapShape:shape toMapView:self.mapView];
                [self addEditableShapeWithFeatureId:featureId andShape:mapShape];
            }
        }
    }
    @finally {
        if(geoPackage != nil){
            [geoPackage close];
        }
    }
}

-(GPKGMapPointOptions *) getEditFeaturePointOptions{
    GPKGMapPointOptions * options = [[GPKGMapPointOptions alloc] init];
    options.draggable = true;
    options.pinColor = MKPinAnnotationColorRed;
    options.initializer = [[GPGKSMapPointInitializer alloc] initWithPointType:GPKGS_MPDT_EDIT_FEATURE_POINT];
    return options;
}

-(GPKGMapPointOptions *) getEditFeatureShapePointOptions{
    GPKGMapPointOptions * options = [[GPKGMapPointOptions alloc] init];
    options.draggable = true;
    [options setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_POINT_IMAGE]];
    options.initializer = [[GPGKSMapPointInitializer alloc] initWithPointType:GPKGS_MPDT_EDIT_FEATURE_POINT];
    return options;
}

-(GPKGMapPointOptions *) getEditFeatureShapeHolePointOptions{
    GPKGMapPointOptions * options = [[GPKGMapPointOptions alloc] init];
    options.draggable = true;
    [options setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_HOLE_POINT_IMAGE]];
    options.initializer = [[GPGKSMapPointInitializer alloc] initWithPointType:GPKGS_MPDT_EDIT_FEATURE_POINT];
    return options;
}

-(void) saveEditFeatures{
    // TODO
}

-(void) updateEditState: (BOOL) updateAcceptClear{
    
    BOOL accept = false;
    
    switch(self.editFeatureType){
            
        case GPKGS_ET_POINT:
            if([self.editPoints count] > 0){
                accept = true;
            }
            break;
            
        case GPKGS_ET_LINESTRING:
            if([self.editPoints count] >= 2){
                accept = true;
                
                NSArray * points = [self getLocationPoints:self.editPoints];
                CLLocationCoordinate2D * locations = [GPKGMapShapeConverter getLocationCoordinatesFromLocations:points];
                MKPolyline * tempPolyline = [MKPolyline polylineWithCoordinates:locations count:[points count]];
                if(self.editLinestring != nil){
                    [self.mapView removeOverlay:self.editLinestring];
                }
                self.editLinestring = tempPolyline;
                [self.mapView addOverlay:self.editLinestring];
            } else if(self.editLinestring != nil){
                [self.mapView removeOverlay:self.editLinestring];
                self.editLinestring = nil;
            }
            break;
            
        case GPKGS_ET_POLYGON:
        case GPKGS_ET_POLYGON_HOLE:
            if([self.editPoints count] >= 3){
                accept = true;
                
                NSArray * points = [self getLocationPoints:self.editPoints];
                CLLocationCoordinate2D * locations = [GPKGMapShapeConverter getLocationCoordinatesFromLocations:points];
                NSMutableArray * polygonHoles = [[NSMutableArray alloc] initWithCapacity:[self.holePolygons count]];
                for(NSArray * holePoints in self.holePolygons){
                    CLLocationCoordinate2D * holeLocations = [GPKGMapShapeConverter getLocationCoordinatesFromLocations:holePoints];
                    MKPolyline * polygonHole = [MKPolyline polylineWithCoordinates:holeLocations count:[holePoints count]];
                    [polygonHoles addObject:polygonHole];
                }
                MKPolygon * tempPolygon  = [MKPolygon polygonWithCoordinates:locations count:[points count] interiorPolygons:polygonHoles];
                if(self.editPolygon != nil){
                    [self.mapView removeOverlay:self.editPolygon];
                }
                self.editPolygon = tempPolygon;
                [self.mapView addOverlay:self.editPolygon];
            } else if(self.editPolygon != nil){
                [self.mapView removeOverlay:self.editPolygon];
                self.editPolygon = nil;
            }
            
            if(self.editFeatureType == GPKGS_ET_POLYGON_HOLE){
                
                if([self.editHolePoints count] > 0){
                    accept = false;
                    [self.editPolygonHoleClearButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_POLYGON_HOLE_CLEAR_ACTIVE_IMAGE] forState:UIControlStateNormal];
                }else{
                    [self.editPolygonHoleClearButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_POLYGON_HOLE_CLEAR_IMAGE] forState:UIControlStateNormal];
                }
                
                if([self.editHolePoints count] >= 3){
                    
                    [self.editPolygonHoleConfirmButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_POLYGON_HOLE_CONFIRM_ACTIVE_IMAGE] forState:UIControlStateNormal];
                    
                    NSArray * points = [self getLocationPoints:self.editHolePoints];
                    CLLocationCoordinate2D * locations = [GPKGMapShapeConverter getLocationCoordinatesFromLocations:points];
                    MKPolygon * tempHolePolygon  = [MKPolygon polygonWithCoordinates:locations count:[points count]];
                    if(self.editHolePolygon != nil){
                        [self.mapView removeOverlay:self.editHolePolygon];
                    }
                    self.editHolePolygon = tempHolePolygon;
                    [self.mapView addOverlay:self.editHolePolygon];
                }else{
                    [self.editPolygonHoleConfirmButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_POLYGON_HOLE_CONFIRM_IMAGE] forState:UIControlStateNormal];
                    if(self.editHolePolygon != nil){
                        [self.mapView removeOverlay:self.editHolePolygon];
                        self.editHolePolygon = nil;
                    }
                }
            }
            break;
            
        case GPKGS_ET_EDIT_FEATURE:
            accept = true;
            
            if(self.editFeatureShape != nil){
                [self.editFeatureShape updateWithMapView:self.mapView];
                accept = [self.editFeatureShape isValid];
            }
            break;
            
        default:
            break;
    }
    
    if(updateAcceptClear){
        if([self.editPoints count] > 0 || self.editFeatureType == GPKGS_ET_EDIT_FEATURE){
            [self.editFeaturesClearButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_FEATURES_CLEAR_ACTIVE_IMAGE] forState:UIControlStateNormal];
        } else{
            [self.editFeaturesClearButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_FEATURES_CLEAR_IMAGE] forState:UIControlStateNormal];
        }
        if(accept){
            [self.editFeaturesConfirmButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_FEATURES_CONFIRM_ACTIVE_IMAGE] forState:UIControlStateNormal];
        }else{
            [self.editFeaturesConfirmButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_FEATURES_CONFIRM_IMAGE] forState:UIControlStateNormal];
        }
    }
}

-(void) resetBoundingBox{
    self.boundingBoxMode = false;
    [self setBoundingBoxButtonsHidden:true];
    [self clearBoundingBox];
}

-(void) resetEditFeatures{
    self.editFeaturesMode = false;
    [self setEditFeaturesButtonsHidden:true];
    self.editFeaturesDatabase = nil;
    self.editFeaturesTable = nil;
    [self.editFeatureIds removeAllObjects];
    [self.editFeatureObjects removeAllObjects];
    self.editFeatureShape = nil;
    self.editFeatureShapePoints = nil;
    self.editFeatureMapPoint = nil;
    self.tempEditFeatureMapPoint = nil;
    [self clearEditFeatures];
}

-(void) clearBoundingBox{
    [self resetBoundingBoxButtonImages];
    if(self.boundingBox != nil){
        [self.mapView removeOverlay:self.boundingBox];
    }
    self.boundingBoxStartCorner = kCLLocationCoordinate2DInvalid;
    self.boundingBoxEndCorner = kCLLocationCoordinate2DInvalid;
    self.boundingBox = nil;
    [self setDrawing:false];
}

-(void) clearEditFeatures{
    self.editFeatureType = GPKGS_ET_NONE;
    for(GPKGMapPoint * editMapPoint in self.editPoints){
        [self.mapView removeAnnotation:editMapPoint];
    }
    [self.editPoints removeAllObjects];
    if(self.editLinestring != nil){
        [self.mapView removeOverlay:self.editLinestring];
        self.editLinestring = nil;
    }
    if(self.editPolygon != nil){
        [self.mapView removeOverlay:self.editPolygon];
        self.editPolygon = nil;
    }
    [self.holePolygons removeAllObjects];
    [self resetEditFeaturesButtonImages];
    [self setEditPolygonHoleButtonsHidden:true];
    [self clearEditHoleFeatures];
    if(self.editFeatureShape != nil){
        [self.editFeatureShape removeFromMapView:self.mapView];
        if(self.editFeatureMapPoint != nil){
            [self addEditableShapeBack];
            self.editFeatureMapPoint = nil;
        }
        self.editFeatureShape = nil;
        self.editFeatureShapePoints = nil;
    }
}

-(void) clearEditHoleFeatures{
    
    for(GPKGMapPoint * editMapPoint in self.editHolePoints){
        [self.mapView removeAnnotation:editMapPoint];
    }
    [self.editHolePoints removeAllObjects];
    if(self.editHolePolygon != nil){
        [self.mapView removeOverlay:self.editHolePolygon];
        self.editHolePolygon = nil;
    }
    [self resetEditPolygonHoleChoiceButtonImages];
}

- (IBAction)userLocation:(id)sender {
    if([CLLocationManager locationServicesEnabled]){
        [self.locationManager startUpdatingLocation];
    }
}

- (IBAction)maxFeaturesButton:(id)sender {
    UIAlertView * alert = [[UIAlertView alloc]
                           initWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_MAX_FEATURES]
                           message:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_MAX_FEATURES_MESSAGE]
                           delegate:self
                           cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                           otherButtonTitles:[GPKGSProperties getValueOfProperty:GPKGS_PROP_OK_LABEL],
                           nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField* textField = [alert textFieldAtIndex:0];
    textField.keyboardType = UIKeyboardTypeNumberPad;
    [textField setText:[NSString stringWithFormat:@"%d", [self getMaxFeatures]]];
    alert.tag = TAG_MAX_FEATURES;
    [alert show];
}

- (void) handleMaxFeaturesWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex > 0){
        NSString * maxFeatures = [[alertView textFieldAtIndex:0] text];
        if(maxFeatures != nil && [maxFeatures length] > 0){
            @try {
                NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                formatter.numberStyle = NSNumberFormatterDecimalStyle;
                NSNumber *maxFeaturesNumber = [formatter numberFromString:maxFeatures];
                [self.settings setInteger:[maxFeaturesNumber integerValue] forKey:GPKGS_PROP_MAP_MAX_FEATURES];
                [self.settings synchronize];
                [self updateInBackgroundWithZoom:false];
            }
            @catch (NSException *e) {
                NSLog(@"Invalid max features value: %@, Error: %@", maxFeatures, [e description]);
            }
        }
    }
}

- (IBAction)mapType:(id)sender {
    UIAlertView * alert = [[UIAlertView alloc]
                           initWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE]
                           message:nil
                           delegate:self
                           cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                           otherButtonTitles:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_STANDARD],
                           [GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_SATELLITE],
                           [GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_HYBRID],
                           nil];
    alert.tag = TAG_MAP_TYPE;
    [alert show];
}

- (void) handleMapTypeWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex > 0){
        MKMapType mapType;
        switch(buttonIndex){
            case 1:
                mapType = MKMapTypeStandard;
                break;
            case 2:
                mapType = MKMapTypeSatellite;
                break;
            case 3:
                mapType = MKMapTypeHybrid;
                break;
            default:
                mapType = MKMapTypeStandard;
        }
        [self.mapView setMapType:mapType];
    }
}

- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation {
    CLLocation * userLocation = self.mapView.userLocation.location;
    if(userLocation != nil){
        
        MKCoordinateRegion region;
        region.center = self.mapView.userLocation.coordinate;
        region.span = MKCoordinateSpanMake(0.02, 0.02);
        
        region = [self.mapView regionThatFits:region];
        [self.mapView setRegion:region animated:YES];
        
        // This pans without zooming instead of the pan and zoom above
        //[self.mapView setCenterCoordinate:userLocation.coordinate animated:YES];
        
        [self.locationManager stopUpdatingLocation];
    }
}

-(int) updateInBackgroundWithZoom: (BOOL) zoom{
    
    int updateId = ++self.updateCountId;
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
    self.featuresBoundingBox = nil;
    self.tilesBoundingBox = nil;
    self.featureOverlayTiles = false;
    int maxFeatures = [self getMaxFeatures];

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        [self updateWithId: updateId andZoom:zoom andMaxFeatures:maxFeatures];
    });
}

-(BOOL) updateCanceled: (int) updateId{
    BOOL canceled = updateId < self.updateCountId;
    return canceled;
}

-(int) updateWithId: (int) updateId andZoom: (BOOL) zoom andMaxFeatures: (int) maxFeatures{
    
    int count = 0;
    
    if(self.active != nil){
        
        // Add tile overlays first
        NSArray * activeDatabases = [[NSArray alloc] initWithArray:[self.active getDatabases]];
        for(GPKGSDatabase * database in activeDatabases){
            
            GPKGGeoPackage * geoPackage = [self.manager open:database.name];
            
            if(geoPackage != nil){
                [self.geoPackages setObject:geoPackage forKey:database.name];
                
                // Display the tiles
                for(GPKGSTileTable * tiles in [database getTiles]){
                    @try {
                        [self displayTiles:tiles];
                    }
                    @catch (NSException *e) {
                        NSLog(@"%@", [e description]);
                    }
                    if([self updateCanceled:updateId]){
                        break;
                    }
                }
             
                // Display the feature tiles
                for(GPKGSFeatureOverlayTable * featureOverlay in [database getFeatureOverlays]){
                    if(featureOverlay.active){
                        @try {
                            [self displayFeatureTiles:featureOverlay];
                        }
                        @catch (NSException *e) {
                            NSLog(@"%@", [e description]);
                        }
                    }
                    if([self updateCanceled:updateId]){
                        break;
                    }
                }
            } else{
                [self.active removeDatabase:database.name andPreserveOverlays:false];
            }
            
            if([self updateCanceled:updateId]){
                break;
            }
        }
        
        // Add features
        NSMutableDictionary * featureTables = [[NSMutableDictionary alloc] init];
        if(self.editFeaturesMode){
            NSMutableArray * databaseFeatures = [[NSMutableArray alloc] init];
            [databaseFeatures addObject:self.editFeaturesTable];
            [featureTables setObject:databaseFeatures forKey:self.editFeaturesDatabase];
            GPKGGeoPackage * geoPackage = [self.geoPackages objectForKey:self.editFeaturesDatabase];
            if(geoPackage == nil){
                geoPackage = [self.manager open:self.editFeaturesDatabase];
                [self.geoPackages setObject:geoPackage forKey:self.editFeaturesDatabase];
            }
        }else{
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
        }
        
        for(NSString * databaseName in [featureTables allKeys]){
            
            if(count >= maxFeatures){
                break;
            }
            
            NSMutableArray * databaseFeatures = [featureTables objectForKey:databaseName];
            
            for(NSString * features in databaseFeatures){
                count = [self displayFeaturesWithId:updateId andDatabase:databaseName andFeatures:features andCount:count andMaxFeatures:maxFeatures andEditable:self.editFeaturesMode];
                if([self updateCanceled:updateId] || count >= maxFeatures){
                    break;
                }
            }
            
            if([self updateCanceled:updateId]){
                break;
            }
        }
    }
    
    if(self.boundingBox != nil){
        [self.mapView addOverlay:self.boundingBox];
    }
    
    if(zoom){
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self zoomToActive];
        });
    }
    
    return count;
}

-(void) zoomToActive{
    
    GPKGBoundingBox * bbox = self.featuresBoundingBox;
    
    float paddingPercentage;
    if(bbox == nil){
        bbox = self.tilesBoundingBox;
        if(self.featureOverlayTiles){
            paddingPercentage = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_FEATURE_TILES_ZOOM_PADDING_PERCENTAGE] intValue] * .01;
        }else{
            paddingPercentage = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_TILES_ZOOM_PADDING_PERCENTAGE] intValue] * .01;
        }
    }else{
        paddingPercentage = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_FEATURES_ZOOM_PADDING_PERCENTAGE] intValue] * .01f;
    }
    
    if(bbox != nil){

        struct GPKGBoundingBoxSize size = [bbox sizeInMeters];
        double expandedHeight = size.height + (2 * (size.height * paddingPercentage));
        double expandedWidth = size.width + (2 * (size.width * paddingPercentage));
        
        CLLocationCoordinate2D center = [bbox getCenter];
        MKCoordinateRegion expandedRegion = MKCoordinateRegionMakeWithDistance(center, expandedHeight, expandedWidth);
        
        double latitudeRange = expandedRegion.span.latitudeDelta / 2.0;
        double longitudeRange = expandedRegion.span.longitudeDelta / 2.0;
        
        if(expandedRegion.center.latitude + latitudeRange > 90.0 || expandedRegion.center.latitude - latitudeRange < -90.0
           || expandedRegion.center.longitude + longitudeRange > 180.0 || expandedRegion.center.longitude - longitudeRange < -180.0){
            expandedRegion = MKCoordinateRegionMake(self.mapView.centerCoordinate, MKCoordinateSpanMake(180, 360));
        }
        
        [self.mapView setRegion:expandedRegion animated:true];
    }
}

-(void) displayTiles: (GPKGSTileTable *) tiles{
    
    GPKGGeoPackage * geoPackage = [self.geoPackages objectForKey:tiles.database];
    
    GPKGTileDao * tileDao = [geoPackage getTileDaoWithTableName:tiles.name];
    
    MKTileOverlay * overlay = [GPKGOverlayFactory getTileOverlayWithTileDao:tileDao];
    overlay.canReplaceMapContent = false;
    
    GPKGTileMatrixSet * tileMatrixSet = tileDao.tileMatrixSet;
    GPKGContents * contents = [[geoPackage getTileMatrixSetDao] getContents:tileMatrixSet];
    
    [self displayTilesWithOverlay:overlay andGeoPackage:geoPackage andContents:contents andSpecifiedBoundingBox:nil];
}

-(void) displayFeatureTiles: (GPKGSFeatureOverlayTable *) featureOverlay{
    
    GPKGGeoPackage * geoPackage = [self.geoPackages objectForKey:featureOverlay.database];
    
    GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:featureOverlay.featureTable];
    
    GPKGBoundingBox * boundingBox = [[GPKGBoundingBox alloc] initWithMinLongitudeDouble:featureOverlay.minLon andMaxLongitudeDouble:featureOverlay.maxLon andMinLatitudeDouble:featureOverlay.minLat andMaxLatitudeDouble:featureOverlay.maxLat];
    
    // Load tiles
    GPKGFeatureTiles * featureTiles = [[GPKGFeatureTiles alloc] initWithFeatureDao:featureDao];
    
    GPKGFeatureIndexer * indexer = [[GPKGFeatureIndexer alloc] initWithFeatureDao:featureDao];
    [featureTiles setIndexQuery:[indexer isIndexed]];
    
    [featureTiles setPointColor:featureOverlay.pointColor];
    [featureTiles setPointRadius:featureOverlay.pointRadius];
    [featureTiles setLineColor:featureOverlay.lineColor];
    [featureTiles setLineStrokeWidth:featureOverlay.lineStroke];
    [featureTiles setPolygonColor:featureOverlay.polygonColor];
    [featureTiles setPolygonStrokeWidth:featureOverlay.polygonStroke];
    [featureTiles setFillPolygon:featureOverlay.polygonFill];
    if(featureTiles.fillPolygon){
        [featureTiles setPolygonFillColor:featureOverlay.polygonFillColor];
    }
    
    [featureTiles calculateDrawOverlap];
    
    GPKGFeatureOverlay * overlay = [[GPKGFeatureOverlay alloc] initWithFeatureTiles:featureTiles];
    [overlay setBoundingBox:boundingBox withProjection:[GPKGProjectionFactory getProjectionWithInt:PROJ_EPSG_WORLD_GEODETIC_SYSTEM]];
    [overlay setMinZoom:[NSNumber numberWithInt:featureOverlay.minZoom]];
    [overlay setMaxZoom:[NSNumber numberWithInt:featureOverlay.maxZoom]];
    
    GPKGGeometryColumns * geometryColumns = featureDao.geometryColumns;
    GPKGContents * contents = [[geoPackage getGeometryColumnsDao] getContents:geometryColumns];
    
    self.featureOverlayTiles = true;
    
    [self displayTilesWithOverlay:overlay andGeoPackage:geoPackage andContents:contents andSpecifiedBoundingBox:boundingBox];
}

-(void) displayTilesWithOverlay: (MKTileOverlay *) overlay andGeoPackage: (GPKGGeoPackage *) geoPackage andContents: (GPKGContents *) contents andSpecifiedBoundingBox: (GPKGBoundingBox *) specifiedBoundingBox{
    
    GPKGContentsDao * contentsDao = [geoPackage getContentsDao];
    GPKGProjection * projection = [contentsDao getProjection:contents];
    
    GPKGProjectionTransform * transformToWebMercator = [[GPKGProjectionTransform alloc] initWithFromProjection:projection andToEpsg:PROJ_EPSG_WEB_MERCATOR];
    
    GPKGBoundingBox * contentsBoundingBox = [contents getBoundingBox];
    if([projection.epsg intValue] == PROJ_EPSG_WORLD_GEODETIC_SYSTEM){
        contentsBoundingBox = [GPKGTileBoundingBoxUtils boundWgs84BoundingBoxWithWebMercatorLimits:contentsBoundingBox];
    }

    GPKGBoundingBox * webMercatorBoundingBox = [transformToWebMercator transformWithBoundingBox:contentsBoundingBox];
    GPKGProjectionTransform * transform = [[GPKGProjectionTransform alloc] initWithFromEpsg:PROJ_EPSG_WEB_MERCATOR andToEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
    GPKGBoundingBox * boundingBox = [transform transformWithBoundingBox:webMercatorBoundingBox];
    
    if(specifiedBoundingBox != nil){
        boundingBox = [GPKGTileBoundingBoxUtils overlapWithBoundingBox:boundingBox andBoundingBox:specifiedBoundingBox];
    }
    
    if(self.tilesBoundingBox == nil){
        self.tilesBoundingBox = boundingBox;
    }else{
        if([boundingBox.minLongitude compare:self.tilesBoundingBox.minLongitude] == NSOrderedAscending){
            [self.tilesBoundingBox setMinLongitude:boundingBox.minLongitude];
        }
        if([boundingBox.maxLongitude compare:self.tilesBoundingBox.maxLongitude] == NSOrderedDescending){
            [self.tilesBoundingBox setMaxLongitude:boundingBox.maxLongitude];
        }
        if([boundingBox.minLatitude compare:self.tilesBoundingBox.minLatitude] == NSOrderedAscending){
            [self.tilesBoundingBox setMinLatitude:boundingBox.minLatitude];
        }
        if([boundingBox.maxLatitude compare:self.tilesBoundingBox.maxLatitude] == NSOrderedDescending){
            [self.tilesBoundingBox setMaxLatitude:boundingBox.maxLatitude];
        }
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.mapView addOverlay:overlay];
    });
}

-(int) displayFeaturesWithId: (int) updateId andDatabase: (NSString *) database andFeatures: (NSString *) features andCount: (int) count andMaxFeatures: (int) maxFeatures andEditable: (BOOL) editable{
    
    GPKGGeoPackage * geoPackage = [self.geoPackages objectForKey:database];
    GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:features];
    
    // Query for all rows
    GPKGResultSet * results = [featureDao queryForAll];
    @try {
        while(![self updateCanceled:updateId] && count < maxFeatures && [results moveToNext]){
            GPKGFeatureRow * row = [featureDao getFeatureRow:results];
            count = [self processFeatureRowWithDatabase:database andFeatureDao:featureDao andFeatureRow:row andCount:count andMaxFeatures:maxFeatures andEditable:editable];
        }
    }
    @finally {
        [results close];
    }
    
    return count;
}

-(int) processFeatureRowWithDatabase: (NSString *) database andFeatureDao: (GPKGFeatureDao *) featureDao andFeatureRow: (GPKGFeatureRow *) row andCount: (int) count andMaxFeatures: (int) maxFeatures andEditable: (BOOL) editable{
    GPKGProjection * projection = featureDao.projection;
    GPKGMapShapeConverter * converter = [[GPKGMapShapeConverter alloc] initWithProjection:projection];
    
    GPKGGeometryData * geometryData = [row getGeometry];
    if(geometryData != nil && !geometryData.empty){
        
        WKBGeometry * geometry = geometryData.geometry;
        
        if(geometry != nil){
            if(count++ < maxFeatures){
                NSNumber * featureId = [row getId];
                GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                [self updateFeaturesBoundingBox:shape];
                [self prepareShapeOptionsWithShape:shape andEditable:editable andTopLevel:true];
                dispatch_sync(dispatch_get_main_queue(), ^{
                    GPKGMapShape * mapShape = [GPKGMapShapeConverter addMapShape:shape toMapView:self.mapView];
                    if(self.editFeaturesMode){
                        [self addEditableShapeWithFeatureId:featureId andShape:mapShape];
                    }else{
                        [self addMapPointShapeWithFeatureId:[featureId intValue] andDatabase:database andTableName:featureDao.tableName andMapShape:mapShape];
                    }
                });
            }
        }
        
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
            [mapPoint.options setPinColor:MKPinAnnotationColorGreen];
        }else{
            [mapPoint.options setPinColor:MKPinAnnotationColorPurple];
        }
    }else{
        [mapPoint.options setPinColor:MKPinAnnotationColorPurple];
    }
    
}

-(void) addEditableShapeWithFeatureId: (NSNumber *) featureId andShape: (GPKGMapShape *) shape{
    
    GPKGMapPoint * mapPoint = nil;
    
    if(shape.shapeType == GPKG_MST_POINT){
        mapPoint = (GPKGMapPoint *) shape.shape;
    }else{
        mapPoint = [self getMapPointWithShape:shape];
        if(mapPoint != nil){
            [self.editFeatureObjects setObject:shape forKey:[mapPoint getIdAsNumber]];
        }
    }
    
    if(mapPoint != nil){
        [self.editFeatureIds setObject:featureId forKey:[mapPoint getIdAsNumber]];
        GPKGSMapPointData * data = [self getOrCreateDataWithMapPoint:mapPoint];
        data.type = GPKGS_MPDT_EDIT_FEATURE;
        data.database = self.editFeaturesDatabase;
        data.tableName = self.editFeaturesTable;
        data.featureId = [featureId intValue];
        [self setTitleWithGeometryType:shape.geometryType andMapPoint:mapPoint];
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

-(GPKGMapPoint *) getMapPointWithShape: (GPKGMapShape *) shape{
    
    GPKGMapPoint * editMapPoint = nil;
    
    switch(shape.shapeType){
            
        case GPKG_MST_POINT:
            {
                GPKGMapPoint * mapPoint = (GPKGMapPoint *) shape.shape;
                editMapPoint = [self createEditMapPointWithMapPoint:mapPoint];
            }
            break;
            
        case GPKG_MST_POLYLINE:
            {
                MKPolyline * polyline = (MKPolyline *) shape.shape;
                MKMapPoint mkMapPoint = polyline.points[0];
                editMapPoint = [self createEditMapPointWithMKMapPoint:mkMapPoint];
            }
            break;
            
        case GPKG_MST_POLYGON:
            {
                MKPolygon * polygon = (MKPolygon *) shape.shape;
                MKMapPoint mkMapPoint = polygon.points[0];
                editMapPoint = [self createEditMapPointWithMKMapPoint:mkMapPoint];
            }
            break;
            
        case GPKG_MST_MULTI_POINT:
            {
                GPKGMultiPoint * multiPoint = (GPKGMultiPoint *) shape.shape;
                GPKGMapPoint * mapPoint = (GPKGMapPoint *) [multiPoint.points objectAtIndex:0];
                editMapPoint = [self createEditMapPointWithMapPoint:mapPoint];
            }
            break;
            
        case GPKG_MST_MULTI_POLYLINE:
            {
                GPKGMultiPolyline * multiPolyline = (GPKGMultiPolyline *) shape.shape;
                MKPolyline * polyline = [multiPolyline.polylines objectAtIndex:0];
                MKMapPoint mkMapPoint = polyline.points[0];
                editMapPoint = [self createEditMapPointWithMKMapPoint:mkMapPoint];
            }
            break;
            
        case GPKG_MST_MULTI_POLYGON:
            {
                GPKGMultiPolygon * multiPolygon = (GPKGMultiPolygon *) shape.shape;
                MKPolygon * polygon = [multiPolygon.polygons objectAtIndex:0];
                MKMapPoint mkMapPoint = polygon.points[0];
                editMapPoint = [self createEditMapPointWithMKMapPoint:mkMapPoint];
            }
            break;
            
        case GPKG_MST_COLLECTION:
            {
                NSArray * shapeArray = (NSArray *) shape.shape;
                for(GPKGMapShape * shape in shapeArray){
                    editMapPoint = [self getMapPointWithShape:shape];
                    if(editMapPoint != nil){
                        break;
                    }
                }
            }
            break;
            
        default:
            break;
            
    }
    
    return editMapPoint;
}

-(GPKGMapPoint *) createEditMapPointWithMapPoint: (GPKGMapPoint *) mapPoint{
    GPKGMapPoint * editMapPoint = [[GPKGMapPoint alloc] initWithLocation:mapPoint.coordinate];
    [self addEditMapPoint:editMapPoint];
    return editMapPoint;
}

-(GPKGMapPoint *) createEditMapPointWithMKMapPoint: (MKMapPoint) mkMapPoint{
    GPKGMapPoint * editMapPoint = [[GPKGMapPoint alloc] initWithMKMapPoint:mkMapPoint];
    [self addEditMapPoint:editMapPoint];
    return editMapPoint;
}

-(void) addEditMapPoint: (GPKGMapPoint *) editMapPoint{
    [editMapPoint.options setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_EXISTING_FEATURE_IMAGE]];
    [self.mapView addAnnotation:editMapPoint];
}

-(int) getMaxFeatures{
    int maxFeatures = (int)[self.settings integerForKey:GPKGS_PROP_MAP_MAX_FEATURES];
    if(maxFeatures == 0){
        maxFeatures = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_MAX_FEATURES_DEFAULT] intValue];
    }
    return maxFeatures;
}

- (void)downloadTilesViewController:(GPKGSDownloadTilesViewController *)controller downloadedTiles:(int)count withError: (NSString *) error{
    self.internalSeg = true;
    if(count > 0){
        GPKGSTable * table = [[GPKGSTileTable alloc] initWithDatabase:controller.databaseValue.text andName:controller.data.name andCount:0];
        [self.active addTable:table];
        
        [self updateInBackgroundWithZoom:false];
        [self.active setModified:true];
    }
    if(error != nil){
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_CREATE_TILES_DIALOG_LABEL]
                                 andMessage:[NSString stringWithFormat:@"Error downloading tiles to table '%@' in database: '%@'\n\nError: %@", controller.data.name, controller.databaseValue.text, error]];
    }
}

- (void)selectFeatureTableViewController:(GPKGSSelectFeatureTableViewController *)controller database:(NSString *)database table: (NSString *) table request: (NSString *) request{
    self.internalSeg = true;
    if([request isEqualToString:GPKGS_MAP_SEG_EDIT_FEATURES_REQUEST]){
        
        if(self.boundingBoxMode){
            [self resetBoundingBox];
        }
        
        self.editFeaturesDatabase = database;
        self.editFeaturesTable = table;
        
        self.editFeaturesMode = true;
        [self setEditFeaturesButtonsHidden:false];
        [self updateInBackgroundWithZoom:false];
        
    }else if ([request isEqualToString:GPKGS_MAP_SEG_FEATURE_TILES_REQUEST]){
        
        GPKGSTable * dbTable = [[GPKGSTable alloc] initWithDatabase:database andName:table andCount:0];
        [self performSegueWithIdentifier:GPKGS_MAP_SEG_CREATE_FEATURE_TILES sender:dbTable];
    }
    
}

- (void)createFeatureTilesViewController:(GPKGSCreateFeatureTilesViewController *)controller createdTiles:(int)count withError: (NSString *) error{
    self.internalSeg = true;
    if(count > 0){
        GPKGSTable * table = [[GPKGSTileTable alloc] initWithDatabase:controller.databaseValue.text andName:controller.nameValue.text andCount:0];
        [self.active addTable:table];
        
        [self updateInBackgroundWithZoom:false];
        [self.active setModified:true];
    }
    if(error != nil){
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_CREATE_FEATURE_TILES_LABEL]
                                 andMessage:[NSString stringWithFormat:@"Error creating feature tiles table '%@' for feature table '%@' in database: '%@'\n\nError: %@", controller.nameValue.text, controller.name, controller.database, error]];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([segue.identifier isEqualToString:GPKGS_MAP_SEG_DOWNLOAD_TILES])
    {
        GPKGSDownloadTilesViewController *downloadTilesViewController = segue.destinationViewController;
        downloadTilesViewController.delegate = self;
        downloadTilesViewController.manager = self.manager;
        downloadTilesViewController.data = [[GPKGSCreateTilesData alloc] init];
        if(self.boundingBox != nil){
            GPKGBoundingBox * bbox =  [self buildBoundingBox];
            [downloadTilesViewController.data.loadTiles.generateTiles setBoundingBox:bbox];
        }
    } else if([segue.identifier isEqualToString:GPKGS_MAP_SEG_SELECT_FEATURE_TABLE]){
        GPKGSSelectFeatureTableViewController * selectFeatureTableViewController = segue.destinationViewController;
        selectFeatureTableViewController.delegate = self;
        selectFeatureTableViewController.manager = self.manager;
        selectFeatureTableViewController.active = self.active;
        selectFeatureTableViewController.request = self.segRequest;
    } else if([segue.identifier isEqualToString:GPKGS_MAP_SEG_CREATE_FEATURE_TILES]){
        GPKGSCreateFeatureTilesViewController *createFeatureTilesViewController = segue.destinationViewController;
        GPKGSTable * table = (GPKGSTable *)sender;
        createFeatureTilesViewController.delegate = self;
        createFeatureTilesViewController.database = table.database;
        createFeatureTilesViewController.name = table.name;
        createFeatureTilesViewController.manager = self.manager;
        createFeatureTilesViewController.featureTilesDrawData = [[GPKGSFeatureTilesDrawData alloc] init];
        createFeatureTilesViewController.generateTilesData =  [[GPKGSGenerateTilesData alloc] init];
        if(self.boundingBox != nil){
            GPKGBoundingBox * bbox =  [self buildBoundingBox];
            [createFeatureTilesViewController.generateTilesData setBoundingBox:bbox];
        }
    } else if([segue.identifier isEqualToString:GPKGS_MAP_SEG_DISPLAY_TEXT]){
        GPKGSDisplayTextViewController *displayTextViewController = segue.destinationViewController;
        if([sender isKindOfClass:[GPKGMapPoint class]]){
            GPKGMapPoint * mapPoint = (GPKGMapPoint *)sender;
            displayTextViewController.titleValue = [self getTitleAndSubtitleWithMapPoint:mapPoint andDelimiter:@" "];
            displayTextViewController.textValue = [self buildInfoForMapPoint:mapPoint];
        }
    }
}

-(NSString *) buildInfoForMapPoint: (GPKGMapPoint *) mapPoint{
    
    NSString * info = nil;
    
    GPKGSMapPointData * data = [self getOrCreateDataWithMapPoint:mapPoint];
    switch(data.type){
        case GPKGS_MPDT_EDIT_FEATURE_POINT:
            //TODO
            break;
        case GPKGS_MPDT_EDIT_FEATURE:
            info = [self buildInfoForExistingFeatureMapPoint:mapPoint];
            break;
        case GPKGS_MPDT_POINT:
            info = [self buildInfoForExistingFeatureMapPoint:mapPoint];
            break;
        case GPKGS_MPDT_NEW_EDIT_POINT:
        case GPKGS_MPDT_NEW_EDIT_HOLE_POINT:
        case GPKGS_MPDT_NONE:
            info = [self buildInfoForGenericMapPoint:mapPoint];
        default:
            break;
    }
    return info;
}

-(NSString *) buildInfoForExistingFeatureMapPoint: (GPKGMapPoint *) mapPoint{
    
    NSMutableString * info = [[NSMutableString alloc] init];
    
    GPKGSMapPointData * data = [self getOrCreateDataWithMapPoint:mapPoint];
    
    GPKGGeoPackage * geoPackage = [self.manager open:data.database];
    @try {
        
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:data.tableName];
        
        NSNumber * featureId = [NSNumber numberWithInt:data.featureId];
        if(featureId != nil){
            GPKGFeatureRow * featureRow = (GPKGFeatureRow *)[featureDao queryForIdObject:featureId];
            
            if(featureRow != nil){
                
                int geometryColumn = [featureRow getGeometryColumnIndex];
                for(int i = 0; i < featureRow.columnCount; i++){
                    if(i != geometryColumn){
                        NSObject * value = [featureRow getValueWithIndex:i];
                        if(value != nil){
                            [info appendFormat:@"%@: %@\n", [featureRow getColumnWithIndex:i].name, value];
                        }
                    }
                }
                
                GPKGGeometryData * geomData = [featureRow getGeometry];
                if(geomData != nil){
                    WKBGeometry * geometry = geomData.geometry;
                    if(geometry != nil){
                        
                        if(info.length > 0){
                            [info appendString:@"\n"];
                        }
                        
                        [info appendString:[WKBGeometryPrinter getGeometryString:geometry]];
                    }
                }
            }
        }
        
    }
    @catch (NSException *e) {
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_EDIT_FEATURES_DELETE_LABEL]
                                 andMessage:[NSString stringWithFormat:@"%@", [e description]]];
    }
    @finally {
        [geoPackage close];
    }
    
    return info;
}

-(NSString *) buildInfoForGenericMapPoint: (GPKGMapPoint *) mapPoint{
    NSMutableString * info = [[NSMutableString alloc] init];
    [info appendFormat:@"Latitude: %f", mapPoint.coordinate.latitude];
    [info appendFormat:@"\nLongitude: %f", mapPoint.coordinate.longitude];
    return info;
}

-(GPKGBoundingBox *) buildBoundingBox{
    double minLat = 90.0;
    double minLon = 180.0;
    double maxLat = -90.0;
    double maxLon = -180.0;
    for(int i = 0; i < self.boundingBox.pointCount; i++){
        MKMapPoint mapPoint = self.boundingBox.points[i];
        CLLocationCoordinate2D coord = MKCoordinateForMapPoint(mapPoint);
        minLat = MIN(minLat, coord.latitude);
        minLon = MIN(minLon, coord.longitude);
        maxLat = MAX(maxLat, coord.latitude);
        maxLon = MAX(maxLon, coord.longitude);
    }
    GPKGBoundingBox * bbox = [[GPKGBoundingBox alloc]initWithMinLongitudeDouble:minLon andMaxLongitudeDouble:maxLon andMinLatitudeDouble:minLat andMaxLatitudeDouble:maxLat];
    return bbox;
}

-(void) setBoundingBoxButtonsHidden: (BOOL) hidden{
    [self.downloadTilesButton setHidden:hidden];
    [self.featureTilesButton setHidden:hidden];
    [self.boundingBoxClearButton setHidden:hidden];
    
    if(hidden){
        [self.boundingBoxButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_BOUNDING_BOX_IMAGE] forState:UIControlStateNormal];
    } else{
        [self.boundingBoxButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_BOUNDING_BOX_ACTIVE_IMAGE] forState:UIControlStateNormal];
    }
    
    [self resetBoundingBoxButtonImages];
}

-(void) resetBoundingBoxButtonImages{
    [self.boundingBoxClearButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_BOUNDING_BOX_CLEAR_IMAGE] forState:UIControlStateNormal];
}

-(void) setEditFeaturesButtonsHidden: (BOOL) hidden{
    
    [self.drawPointButton setHidden:hidden];
    [self.drawLineButton setHidden:hidden];
    [self.drawPolygonButton setHidden:hidden];
    [self.editFeaturesConfirmButton setHidden:hidden];
    [self.editFeaturesClearButton setHidden:hidden];
    
    if(hidden){
        [self.featuresButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_FEATURES_IMAGE] forState:UIControlStateNormal];
    } else{
        [self.featuresButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_FEATURES_ACTIVE_IMAGE] forState:UIControlStateNormal];
    }
    
    [self resetEditFeaturesButtonImages];
    
    if(hidden){
        [self setEditPolygonHoleButtonsHidden:true];
    }
}

-(void) resetEditFeaturesButtonImages{
    [self.drawPointButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_DRAW_POINT_IMAGE] forState:UIControlStateNormal];
    [self.drawLineButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_DRAW_LINE_IMAGE] forState:UIControlStateNormal];
    [self.drawPolygonButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_DRAW_POLYGON_IMAGE] forState:UIControlStateNormal];
    [self.editFeaturesConfirmButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_FEATURES_CONFIRM_IMAGE] forState:UIControlStateNormal];
    [self.editFeaturesClearButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_FEATURES_CLEAR_IMAGE] forState:UIControlStateNormal];
}

-(void) setEditPolygonHoleButtonsHidden: (BOOL) hidden{
    
    [self.drawPolygonHoleButton setHidden:hidden];
    [self.editPolygonHoleConfirmButton setHidden:hidden];
    [self.editPolygonHoleClearButton setHidden:hidden];
    
    [self resetEditPolygonHoleButtonImages];
}

-(void) resetEditPolygonHoleButtonImages{
    [self.drawPolygonHoleButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_DRAW_POLYGON_HOLE_IMAGE] forState:UIControlStateNormal];
    [self resetEditPolygonHoleChoiceButtonImages];
}

-(void) resetEditPolygonHoleChoiceButtonImages{
    [self.editPolygonHoleConfirmButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_POLYGON_HOLE_CONFIRM_IMAGE] forState:UIControlStateNormal];
    [self.editPolygonHoleClearButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_POLYGON_HOLE_CLEAR_IMAGE] forState:UIControlStateNormal];
}

-(GPKGSMapPointData *) getOrCreateDataWithMapPoint: (GPKGMapPoint *) mapPoint{
    if(mapPoint.data == nil){
        mapPoint.data = [[GPKGSMapPointData alloc] init];
    }
    return (GPKGSMapPointData *) mapPoint.data;
}

-(void) setTitleWithMapPoint: (GPKGMapPoint *) mapPoint{
    [self setTitleWithTitle:nil andMapPoint:mapPoint];
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

-(void) updateTitleWithMapPoint: (GPKGMapPoint *) mapPoint{
    
    NSString * locationTitle = [self buildLocationTitleWithMapPoint:mapPoint];
    
    if(mapPoint.subtitle != nil){
        [mapPoint setSubtitle:locationTitle];
    } else{
        [mapPoint setTitle:locationTitle];
    }
}

-(NSString *) buildLocationTitleWithMapPoint: (GPKGMapPoint *) mapPoint{
    
    CLLocationCoordinate2D coordinate = mapPoint.coordinate;
    
    NSString *lat = [self.locationDecimalFormatter stringFromNumber:[NSNumber numberWithDouble:coordinate.latitude]];
    NSString *lon = [self.locationDecimalFormatter stringFromNumber:[NSNumber numberWithDouble:coordinate.longitude]];
    
    NSString * title = [NSString stringWithFormat:@"(lat=%@, lon=%@)", lat, lon];
    
    return title;
}
-(NSString *) getTitleAndSubtitleWithMapPoint: (GPKGMapPoint *) mapPoint andDelimiter: (NSString *) delimiter{
    NSMutableString * value = [[NSMutableString alloc] init];
    [value appendString:mapPoint.title];
    if(mapPoint.subtitle != nil){
        if(delimiter != nil){
            [value appendString:delimiter];
        }
        [value appendString:mapPoint.subtitle];
    }
    return value;
}

@end
