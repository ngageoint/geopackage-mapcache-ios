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
#import "SFPProjectionTransform.h"
#import "SFPProjectionConstants.h"
#import "SFPProjectionFactory.h"
#import "GPKGTileBoundingBoxUtils.h"
#import "GPKGSFeatureOverlayTable.h"
#import "GPKGMapShapeConverter.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGFeatureTiles.h"
#import "GPKGFeatureOverlay.h"
#import "GPKGSUtils.h"
#import "GPKGUtils.h"
#import "GPKGSDownloadTilesViewController.h"
#import "GPKGSCreateTilesData.h"
#import "GPKGSSelectFeatureTableViewController.h"
#import "GPKGSCreateFeatureTilesViewController.h"
#import "GPKGSMapPointData.h"
#import "GPKGSEditTypes.h"
#import "GPKGSDisplayTextViewController.h"
#import "SFGeometryPrinter.h"
#import "GPKGShapePoints.h"
#import "GPKGShapeWithChildrenPoints.h"
#import "GPGKSMapPointInitializer.h"
#import "GPKGNumberFeaturesTile.h"
#import "GPKGFeatureOverlayQuery.h"
#import "GPKGFeatureTileTableLinker.h"
#import "GPKGFeatureShapes.h"
#import "GPKGMapUtils.h"
#import "SFGeometryEnvelopeBuilder.h"
#import "GPKGMultipleFeatureIndexResults.h"
#import "GPKGFeatureIndexListResults.h"
#import "GPKGTileTableScaling.h"
#import "GPKGGeoPackageCache.h"

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
@property (nonatomic, strong) GPKGGeoPackageCache * geoPackages;
@property (nonatomic, strong) NSMutableDictionary * featureDaos;
@property (nonatomic, strong) GPKGBoundingBox * featuresBoundingBox;
@property (nonatomic, strong) GPKGBoundingBox * tilesBoundingBox;
@property (nonatomic) BOOL featureOverlayTiles;
@property (strong, nonatomic) CLLocationManager *locationManager;
@property (nonatomic, strong) NSUserDefaults * settings;
@property (atomic) int updateCountId;
@property (atomic) int featureUpdateCountId;
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
@property (nonatomic) BOOL internalSeg;
@property (nonatomic, strong) NSString * segRequest;
@property (nonatomic, strong) GPKGMapPoint * selectedMapPoint;
@property (nonatomic, strong) NSNumberFormatter *locationDecimalFormatter;
@property (nonatomic, strong) NSMutableArray * featureOverlayQueries;
@property (nonatomic, strong) GPKGFeatureShapes * featureShapes;
@property (nonatomic) int currentZoom;
@property (nonatomic) BOOL needsInitialZoom;
@property (nonatomic) BOOL ignoreRegionChange;

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
    self.featureUpdateCountId = 0;
    self.settings = [NSUserDefaults standardUserDefaults];
    self.mapView.delegate = self;
    self.mapView.showsUserLocation = YES;
    self.manager = [GPKGGeoPackageFactory getManager];
    self.active = [GPKGSDatabases getInstance];
    self.geoPackages = [[GPKGGeoPackageCache alloc] initWithManager:self.manager];
    self.featureDaos = [[NSMutableDictionary alloc] init];
    self.locationManager = [[CLLocationManager alloc] init];
    [self.locationManager setDelegate:self];
    [self.locationManager requestWhenInUseAuthorization];
    self.editFeatureIds = [[NSMutableDictionary alloc] init];
    self.editFeatureObjects = [[NSMutableDictionary alloc] init];
    self.editFeatureType = GPKGS_ET_NONE;
    self.editPoints = [[NSMutableArray alloc] init];
    self.editHolePoints = [[NSMutableArray alloc] init];
    self.holePolygons = [[NSMutableArray alloc] init];
    self.featureOverlayQueries = [[NSMutableArray alloc] init];
    self.featureShapes = [[GPKGFeatureShapes alloc] init];
    self.currentZoom = -1;
    self.needsInitialZoom = true;
    self.ignoreRegionChange = false;
    [self resetBoundingBox];
    [self resetEditFeatures];
    UITapGestureRecognizer * singleTapGesture = [[UITapGestureRecognizer alloc]
                                          initWithTarget:self action:@selector(singleTapGesture:)];
    singleTapGesture.numberOfTapsRequired = 1;
    [self.mapView addGestureRecognizer:singleTapGesture];
    UITapGestureRecognizer * doubleTapGesture = [[UITapGestureRecognizer alloc]
                                                 initWithTarget:self action:@selector(doubleTapGesture:)];
    doubleTapGesture.numberOfTapsRequired = 2;
    [self.mapView addGestureRecognizer:doubleTapGesture];
    [self.mapView addGestureRecognizer:[[UILongPressGestureRecognizer alloc]
                                        initWithTarget:self action:@selector(longPressGesture:)]];
    [singleTapGesture requireGestureRecognizerToFail:doubleTapGesture];
    self.boundingBoxStartCorner = kCLLocationCoordinate2DInvalid;
    self.boundingBoxEndCorner = kCLLocationCoordinate2DInvalid;
    
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
            if(self.editFeatureType == GPKGS_ET_NONE || ([self.editPoints count] == 0 && self.editFeatureMapPoint == nil)){
                polygonRenderer.strokeColor = self.editPolygonColor;
                polygonRenderer.lineWidth = self.editPolygonLineWidth;
                if(self.editPolygonFillColor != nil){
                    polygonRenderer.fillColor = self.editPolygonFillColor;
                }
            }else{
                polygonRenderer.strokeColor = self.drawPolygonColor;
                polygonRenderer.lineWidth = self.drawPolygonLineWidth;
                if(self.drawPolygonFillColor != nil){
                    polygonRenderer.fillColor = self.drawPolygonFillColor;
                }
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
            if(self.editFeatureType == GPKGS_ET_NONE || ([self.editPoints count] == 0 && self.editFeatureMapPoint == nil)){
                polylineRenderer.strokeColor = self.editPolylineColor;
                polylineRenderer.lineWidth = self.editPolylineLineWidth;
            }else{
                polylineRenderer.strokeColor = self.drawPolylineColor;
                polylineRenderer.lineWidth = self.drawPolylineLineWidth;
            }
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
            mapPointPinView.pinTintColor = mapPoint.options.pinTintColor;
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

//-(void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control {
//    
//}

-(void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated{
    
    if(self.ignoreRegionChange){
        self.ignoreRegionChange = false;
    }else{
    
        // If not editing a shape, update the feature shapes for the current map view region
        if(!self.editFeaturesMode || self.editFeatureType == GPKGS_ET_NONE || ([self.editPoints count] == 0 && self.editFeatureMapPoint == nil)){
            
            int updateId = ++self.featureUpdateCountId;
            
            int previousZoom = self.currentZoom;
            int zoom = (int)[GPKGMapUtils currentZoomWithMapView:self.mapView];
            self.currentZoom = zoom;
            if(zoom != previousZoom){
                // Zoom level changed, remove all feature shapes
                [self.featureShapes removeShapesFromMapView:mapView];
            }else{
                // Remove shapes no longer visible on the map view
                [self.featureShapes removeShapesNotWithinMapView:mapView];
            }
            
            GPKGBoundingBox *mapViewBoundingBox = [GPKGMapUtils boundingBoxOfMapView:self.mapView];
            double toleranceDistance = [GPKGMapUtils toleranceDistanceInMapView:self.mapView];
            
            int maxFeatures = [self getMaxFeatures];
            dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
            dispatch_async(queue, ^{
                [self addFeaturesWithId:updateId andMaxFeatures:maxFeatures andMapViewBoundingBox:mapViewBoundingBox andToleranceDistance:toleranceDistance andFilter:YES];
            });
        }
    }
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
    }else{
        // Click on an actual point being edited
        [self performSegueWithIdentifier:GPKGS_MAP_SEG_DISPLAY_TEXT sender:mapPoint];
    }
}

- (void) handleEditFeatureShapeWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if(buttonIndex >= 0){
        
        GPKGMapPoint *mapPoint = objc_getAssociatedObject(alertView, &MapConstantKey);
        NSObject<GPKGShapePoints> * shapePoints = [self.editFeatureShape getShapePointsForPoint:mapPoint];
        
        switch(buttonIndex){
            case 0:
                [self.editFeatureShape deletePoint:mapPoint fromMapView:self.mapView];
                [self updateEditState:true];
                break;
            case 1:
                self.editFeatureShapePoints = shapePoints;
                break;
            case 2:
                if([[shapePoints class] conformsToProtocol:@protocol(GPKGShapeWithChildrenPoints)]){
                    NSObject<GPKGShapeWithChildrenPoints> * shapeWithChildrenPoints = (NSObject<GPKGShapeWithChildrenPoints> *) shapePoints;
                    self.editFeatureShapePoints = [shapeWithChildrenPoints createChild];
                }
                break;
            default:
                break;
        }
    }
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

-(void) expandBoundsWithGeoPackage: (GPKGGeoPackage *) geoPackage andFeatureDao: (GPKGFeatureDao *) featureDao andGeometry: (SFGeometry *) geometry{
    if(geometry !=  nil){
        @try {
            GPKGGeometryColumnsDao * geometryColumnsDao = [geoPackage getGeometryColumnsDao];
            GPKGContents * contents = [geometryColumnsDao getContents:featureDao.geometryColumns];
            GPKGBoundingBox *boundingBox = [contents getBoundingBox];
            if(boundingBox != nil){
                
                SFGeometryEnvelope *envelope = [SFGeometryEnvelopeBuilder buildEnvelopeWithGeometry:geometry];
                GPKGBoundingBox *geometryBoundingBox = [[GPKGBoundingBox alloc] initWithGeometryEnvelope:envelope];
                GPKGBoundingBox *unionBoundingBox = [boundingBox union:geometryBoundingBox];
                
                [contents setBoundingBox:unionBoundingBox];
                GPKGContentsDao * contentsDao = [geoPackage getContentsDao];
                [contentsDao update:contents];
            }
            
        }
        @catch (NSException *e) {
            NSLog(@"Failed to update contents bounding box. GeoPackage: %@, Table: %@, Error:%@", geoPackage.name, featureDao.tableName, [e description]);
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

-(void) singleTapGesture:(UITapGestureRecognizer *) tapGestureRecognizer{
    
    if(!self.editFeaturesMode && tapGestureRecognizer.state == UIGestureRecognizerStateEnded){
        
        NSMutableString * clickMessage = [[NSMutableString alloc] init];
        
        if(self.featureOverlayQueries.count > 0){
            CGPoint cgPoint = [tapGestureRecognizer locationInView:self.mapView];
            CLLocationCoordinate2D point = [self.mapView convertPoint:cgPoint toCoordinateFromView:self.mapView];
            
            for(GPKGFeatureOverlayQuery * query in self.featureOverlayQueries){
                NSString * message = [query buildMapClickMessageWithLocationCoordinate:point andMapView:self.mapView];
                if(message != nil){
                    if(clickMessage.length > 0){
                        [clickMessage appendString:@"\n\n"];
                    }
                    [clickMessage appendString:message];
                }
            }
            
        }
        
        for (GPKGSDatabase *database in [self.active getDatabases]) {
            if([database getFeatures].count > 0){
                CGPoint cgPoint = [tapGestureRecognizer locationInView:self.mapView];
                CLLocationCoordinate2D point = [self.mapView convertPoint:cgPoint toCoordinateFromView:self.mapView];
                
                float screenClickPercentage = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_FEATURE_CLICK_SCREEN_PERCENTAGE] floatValue];
                
                GPKGBoundingBox *clickBoundingBox = [GPKGMapUtils buildClickBoundingBoxWithLocationCoordinate:point andMapView:self.mapView andScreenPercentage:screenClickPercentage];
                clickBoundingBox = [clickBoundingBox expandWgs84Coordinates];
                SFPProjection *clickProjection = [SFPProjectionFactory projectionWithEpsgInt:PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
                
                GPKGMapTolerance *tolerance = [GPKGMapUtils toleranceWithLocationCoordinate:point andMapView:self.mapView andScreenPercentage:screenClickPercentage];
                
                for(GPKGSTable *features in [database getFeatures]){
                    
                    GPKGGeoPackage *geoPackage = [self.geoPackages get:database.name];
                    NSDictionary *databaseFeatureDaos = [self.featureDaos objectForKey:database.name];
                    
                    if(geoPackage != nil && databaseFeatureDaos != nil){
                        
                        GPKGFeatureDao *featureDao = [databaseFeatureDaos objectForKey:features.name];
                        
                        if (featureDao != nil) {
                            
                            GPKGFeatureIndexResults *indexResults = nil;
                            
                            GPKGFeatureIndexManager *indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
                            @try{
                                if ([indexer isIndexed]) {
                                    
                                    indexResults = [indexer queryWithBoundingBox:clickBoundingBox inProjection:clickProjection];
                                    GPKGBoundingBox *complementary = [clickBoundingBox complementaryWgs84];
                                    if (complementary != nil) {
                                        GPKGFeatureIndexResults *indexResults2 = [indexer queryWithBoundingBox:complementary inProjection:clickProjection];
                                        indexResults = [[GPKGMultipleFeatureIndexResults alloc] initWithFeatureIndexResults1:indexResults andFeatureIndexResults2:indexResults2];
                                    }
                                    
                                } else {
                                    
                                    SFPProjection *featureProjection = featureDao.projection;
                                    SFPProjectionTransform *projectionTransform = [[SFPProjectionTransform alloc] initWithFromProjection:clickProjection andToProjection:featureProjection];
                                    GPKGBoundingBox *boundedClickBoundingBox = [clickBoundingBox boundWgs84Coordinates];
                                    GPKGBoundingBox *transformedBoundingBox = [boundedClickBoundingBox transform:projectionTransform];
                                    enum SFPUnit unit = [featureProjection getUnit];
                                    double filterMaxLongitude = 0;
                                    if(unit == SFP_UNIT_DEGREES){
                                        filterMaxLongitude = PROJ_WGS84_HALF_WORLD_LON_WIDTH;
                                    }else if(unit == SFP_UNIT_METERS){
                                        filterMaxLongitude = PROJ_WEB_MERCATOR_HALF_WORLD_WIDTH;
                                    }
                                    
                                    GPKGFeatureIndexListResults *listResults = [[GPKGFeatureIndexListResults alloc] init];
                                    
                                    // Query for all rows
                                    GPKGResultSet * results = [featureDao queryForAll];
                                    @try {
                                        while([results moveToNext]){
                                            @try {
                                                GPKGFeatureRow * row = [featureDao getFeatureRow:results];
                                                
                                                GPKGGeometryData *geometryData = [row getGeometry];
                                                if(geometryData != nil && !geometryData.empty){
                                                    
                                                    SFGeometry *geometry = geometryData.geometry;
                                                    
                                                    if (geometry != nil) {
                                                        
                                                        SFGeometryEnvelope *envelope = geometryData.envelope;
                                                        if (envelope == nil) {
                                                            envelope = [SFGeometryEnvelopeBuilder buildEnvelopeWithGeometry:geometry];
                                                        }
                                                        if (envelope != nil) {
                                                            GPKGBoundingBox *geometryBoundingBox = [[GPKGBoundingBox alloc] initWithGeometryEnvelope:envelope];
                                                            
                                                            if([GPKGTileBoundingBoxUtils overlapWithBoundingBox:transformedBoundingBox andBoundingBox:geometryBoundingBox withMaxLongitude:filterMaxLongitude] != nil){
                                                                [listResults addRow:row];
                                                            }
                                                            
                                                        }
                                                    }
                                                }
                                                
                                            } @catch (NSException *e) {
                                                NSLog(@"Failed to query feature. database: %@, feature table: %@, Error: %@",
                                                      database.name, features.name, [e description]);
                                            }
                                        }
                                        
                                    } @finally {
                                        [results close];
                                    }
                                    
                                    indexResults = listResults;
                                }
                            }@finally{
                                [indexer close];
                            }
                            
                            if ([indexResults count] > 0) {
                                GPKGFeatureInfoBuilder *featureInfoBuilder = [[GPKGFeatureInfoBuilder alloc] initWithFeatureDao:featureDao];
                                [featureInfoBuilder ignoreGeometryType:SF_POINT];
                                NSString *message = [featureInfoBuilder buildResultsInfoMessageAndCloseWithFeatureIndexResults:indexResults andTolerance:tolerance andLocationCoordinate:point];
                                if(message != nil){
                                    if(clickMessage.length > 0){
                                        [clickMessage appendString:@"\n\n"];
                                    }
                                    [clickMessage appendString:message];
                                }
                            }
                        }
                        
                    }
                }
            }
        }
        
        if(clickMessage.length > 0){
            [GPKGSUtils showMessageWithDelegate:self
                                       andTitle:nil
                                     andMessage:clickMessage];
        }
    }
}

-(void) doubleTapGesture:(UITapGestureRecognizer *) tapGestureRecognizer{
    
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
            if([self.editFeatureShapePoints isKindOfClass:[GPKGPolygonHolePoints class]]){
                [mapPoint.options setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_HOLE_POINT_IMAGE]];
            }else if([self.editFeatureShapePoints isKindOfClass:[GPKGMultiPoint class]]){
                [mapPoint.options setPinTintColor:[UIColor redColor]];
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
        [self updateInBackgroundWithZoom:false andFilter:true];
    }
}

- (IBAction)boundingBoxButton:(id)sender {
    if(!self.boundingBoxMode){
        
        if(self.editFeaturesMode){
            [self resetEditFeatures];
            [self updateInBackgroundWithZoom:false andFilter:true];
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
        [self clearEditFeaturesAndUpdateType:(enum GPKGSEditType)[editTypeClicked intValue]];
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
                        SFGeometry * geometry = [featureRow getGeometry].geometry;
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
            SFGeometry * geometry = geomData.geometry;
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
    options.pinTintColor = [UIColor redColor];
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
    
    BOOL changesMade = false;
    
    GPKGGeoPackage * geoPackage = [self.manager open:self.editFeaturesDatabase];
    GPKGFeatureIndexManager *indexer = nil;
    enum GPKGSEditType tempEditFeatureType = self.editFeatureType;
    @try {
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:self.editFeaturesTable];
        NSNumber * srsId = featureDao.geometryColumns.srsId;
        indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
        NSArray<NSString *> *indexedTypes = [indexer indexedTypes];
        
        GPKGMapShapeConverter * converter = [[GPKGMapShapeConverter alloc] initWithProjection:featureDao.projection];
        
        switch(self.editFeatureType){
                
            case GPKGS_ET_POINT:
                {
                    for(GPKGMapPoint * mapPoint in self.editPoints){
                        SFPoint * point = [converter toPointWithMapPoint:mapPoint];
                        GPKGFeatureRow * newPoint = [featureDao newRow];
                        GPKGGeometryData * pointGeomData = [[GPKGGeometryData alloc] initWithSrsId:srsId];
                        [pointGeomData setGeometry:point];
                        [newPoint setGeometry:pointGeomData];
                        [featureDao insert:newPoint];
                        [self expandBoundsWithGeoPackage:geoPackage andFeatureDao:featureDao andGeometry:point];
                        [self updateLastChangeWithGeoPackage:geoPackage andFeatureDao:featureDao];
                        if(indexedTypes.count > 0){
                            [indexer indexWithFeatureRow:newPoint andFeatureIndexTypes:indexedTypes];
                        }
                    }
                    changesMade = true;
                }
                break;
                
            case GPKGS_ET_LINESTRING:
                {
                    SFLineString * lineString = [converter toLineStringWithMapPolyline:self.editLinestring];
                    GPKGFeatureRow * newLineString = [featureDao newRow];
                    GPKGGeometryData * lineStringGeomData = [[GPKGGeometryData alloc] initWithSrsId:srsId];
                    [lineStringGeomData setGeometry:lineString];
                    [newLineString setGeometry:lineStringGeomData];
                    [featureDao insert:newLineString];
                    [self expandBoundsWithGeoPackage:geoPackage andFeatureDao:featureDao andGeometry:lineString];
                    [self updateLastChangeWithGeoPackage:geoPackage andFeatureDao:featureDao];
                    if(indexedTypes.count > 0){
                        [indexer indexWithFeatureRow:newLineString andFeatureIndexTypes:indexedTypes];
                    }
                    changesMade = true;
                }
                break;
                
            case GPKGS_ET_POLYGON:
            case GPKGS_ET_POLYGON_HOLE:
                {
                    SFPolygon * polygon = [converter toPolygonWithMapPolygon:self.editPolygon];
                    GPKGFeatureRow * newPolygon = [featureDao newRow];
                    GPKGGeometryData * polygonGeomData = [[GPKGGeometryData alloc] initWithSrsId:srsId];
                    [polygonGeomData setGeometry:polygon];
                    [newPolygon setGeometry:polygonGeomData];
                    [featureDao insert:newPolygon];
                    [self expandBoundsWithGeoPackage:geoPackage andFeatureDao:featureDao andGeometry:polygon];
                    [self updateLastChangeWithGeoPackage:geoPackage andFeatureDao:featureDao];
                    if(indexedTypes.count > 0){
                        [indexer indexWithFeatureRow:newPolygon andFeatureIndexTypes:indexedTypes];
                    }
                    changesMade = true;
                }
                break;
                
            case GPKGS_ET_EDIT_FEATURE:
                {
                    self.editFeatureType = GPKGS_ET_NONE;
                    NSNumber * featureId = [self.editFeatureIds objectForKey:[self.editFeatureMapPoint getIdAsNumber]];
                    
                    SFGeometry * geometry = [converter toGeometryFromMapShape:self.editFeatureShape.shape];
                    if(geometry != nil){
                        GPKGFeatureRow * featureRow = (GPKGFeatureRow *)[featureDao queryForIdObject:featureId];
                        GPKGGeometryData * geomData = [featureRow getGeometry];
                        [geomData setGeometry:geometry];
                        if(geomData.envelope != nil){
                            geomData.envelope = [SFGeometryEnvelopeBuilder buildEnvelopeWithGeometry:geometry];
                        }
                        [featureRow setGeometry:geomData];
                        [featureDao update:featureRow];
                        [self expandBoundsWithGeoPackage:geoPackage andFeatureDao:featureDao andGeometry:geometry];
                        [self updateLastChangeWithGeoPackage:geoPackage andFeatureDao:featureDao];
                        if(indexedTypes.count > 0){
                            [indexer indexWithFeatureRow:featureRow andFeatureIndexTypes:indexedTypes];
                        }
                    }else{
                        [featureDao deleteById:featureId];
                        self.editFeatureMapPoint = nil;
                        [self updateLastChangeWithGeoPackage:geoPackage andFeatureDao:featureDao];
                        if(indexedTypes.count > 0){
                            [indexer deleteIndexWithGeomId:[featureId intValue] andFeatureIndexTypes:indexedTypes];
                        }
                    }
                    [self.active setModified:true];
                }
                break;
                
            default:
                break;
        }
        
    }
    @catch (NSException *e) {
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:[NSString stringWithFormat:@"Save %@", [GPKGSEditTypes name:tempEditFeatureType]]
                                 andMessage:[NSString stringWithFormat:@"%@", [e description]]];
    }
    @finally {
        if(indexer != nil){
            [indexer close];
        }
        if(geoPackage != nil){
            [geoPackage close];
        }
    }
    
    [self clearEditFeaturesAndPreserveType];
    
    if(changesMade){
        [self.active setModified:true];
        [self updateInBackgroundWithZoom:false andFilter:true];
    }
}

-(void) updateEditState: (BOOL) updateAcceptClear{
    
    BOOL accept = false;
    MKPolygon * editHolePolygon = nil;
    
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
            
        case GPKGS_ET_POLYGON_HOLE:
            
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
                    editHolePolygon = [MKPolygon polygonWithCoordinates:locations count:[points count]];
                }else{
                    [self.editPolygonHoleConfirmButton setImage:[UIImage imageNamed:GPKGS_MAP_BUTTON_EDIT_POLYGON_HOLE_CONFIRM_IMAGE] forState:UIControlStateNormal];
                }
            }
            
            // Continue to polygon
            
        case GPKGS_ET_POLYGON:
            
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
                if(editHolePolygon != nil){
                    [polygonHoles addObject:editHolePolygon];
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
                [self updateInBackgroundWithZoom:false andFilter:true];
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

-(void) updateInBackgroundWithZoom: (BOOL) zoom{
    [self updateInBackgroundWithZoom:zoom andFilter:false];
}

-(void) updateInBackgroundWithZoom: (BOOL) zoom andFilter: (BOOL) filter{
    
    int updateId = ++self.updateCountId;
    int featureUpdateId = ++self.featureUpdateCountId;
    [self.mapView removeAnnotations:self.mapView.annotations];
    [self.mapView removeOverlays:self.mapView.overlays];
    [self.geoPackages closeAll];
    [self.featureDaos removeAllObjects];
    
    if(zoom){
        [self zoomToActiveBounds];
    }
    
    self.featuresBoundingBox = nil;
    self.tilesBoundingBox = nil;
    self.featureOverlayTiles = false;
    [self.featureOverlayQueries removeAllObjects];
    [self.featureShapes clear];
    int maxFeatures = [self getMaxFeatures];
    
    GPKGBoundingBox *mapViewBoundingBox = [GPKGMapUtils boundingBoxOfMapView:self.mapView];
    double toleranceDistance = [GPKGMapUtils toleranceDistanceInMapView:self.mapView];

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0ul);
    dispatch_async(queue, ^{
        [self updateWithId: updateId andFeatureUpdateId:featureUpdateId andZoom:zoom andMaxFeatures:maxFeatures andMapViewBoundingBox:mapViewBoundingBox andToleranceDistance:toleranceDistance andFilter:filter];
    });
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
                            
                            contentsBoundingBox = [self transformBoundingBoxToWgs84: contentsBoundingBox withSrs: [contentsDao getSrs:contents]];
                            
                            if (self.featuresBoundingBox != nil) {
                                self.featuresBoundingBox = [self.featuresBoundingBox union:contentsBoundingBox];
                            } else {
                                self.featuresBoundingBox = contentsBoundingBox;
                            }
                        }
                    } @catch (NSException *e) {
                        NSLog(@"%@", [e description]);
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
                        
                        tileMatrixSetBoundingBox = [self transformBoundingBoxToWgs84:tileMatrixSetBoundingBox withSrs:[tileMatrixSetDao getSrs:tileMatrixSet]];
                        
                        if (self.tilesBoundingBox != nil) {
                            self.tilesBoundingBox = [self.tilesBoundingBox union:tileMatrixSetBoundingBox];
                        } else {
                            self.tilesBoundingBox = tileMatrixSetBoundingBox;
                        }
                    } @catch (NSException *e) {
                        NSLog(@"%@", [e description]);
                    }
                }
            }
            
            [geoPackage close];
        }
    }
    [self zoomToActiveAndIgnoreRegionChange:YES];
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

-(BOOL) updateCanceled: (int) updateId{
    BOOL canceled = updateId < self.updateCountId;
    return canceled;
}

-(BOOL) featureUpdateCanceled: (int) updateId{
    BOOL canceled = updateId < self.featureUpdateCountId;
    return canceled;
}

-(int) updateWithId: (int) updateId andFeatureUpdateId: (int) featureUpdateId andZoom: (BOOL) zoom andMaxFeatures: (int) maxFeatures andMapViewBoundingBox: (GPKGBoundingBox *) mapViewBoundingBox andToleranceDistance: (double) toleranceDistance andFilter: (BOOL) filter{
    
    int count = 0;
    
    if(self.active != nil){
        
        NSArray * activeDatabases = [[NSArray alloc] initWithArray:[self.active getDatabases]];
        
        // Open active GeoPackages and create feature DAOS, display tiles and feature tiles
        for(GPKGSDatabase * database in activeDatabases){
            
            if([self updateCanceled:updateId]){
                break;
            }
            
            GPKGGeoPackage *geoPackage = [self.geoPackages getOrOpen:database.name];
            
            if(geoPackage != nil){
            
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
                        
                        if([self updateCanceled:updateId]){
                            break;
                        }
                        
                        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:featureTable];
                        [databaseFeatureDaos setObject:featureDao forKey:featureTable];
                    }
                }
                
                // Display the tiles
                for(GPKGSTileTable * tiles in [database getTiles]){
                    if([self updateCanceled:updateId]){
                        break;
                    }
                    @try {
                        [self displayTiles:tiles];
                    }
                    @catch (NSException *e) {
                        NSLog(@"%@", [e description]);
                    }
                }
                
                // Display the feature tiles
                for(GPKGSFeatureOverlayTable * featureOverlay in [database getFeatureOverlays]){
                    if([self updateCanceled:updateId]){
                        break;
                    }
                    if(featureOverlay.active){
                        @try {
                            [self displayFeatureTiles:featureOverlay];
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
    
    if(self.boundingBox != nil){
        [self.mapView addOverlay:self.boundingBox];
    }
    
    if(self.needsInitialZoom || zoom){
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self zoomToActiveIfNothingVisible:YES];
            self.needsInitialZoom = false;
        });
    }
    
    return count;
}

-(int) addFeaturesWithId: (int) updateId andMaxFeatures: (int) maxFeatures andMapViewBoundingBox: (GPKGBoundingBox *) mapViewBoundingBox andToleranceDistance: (double) toleranceDistance andFilter: (BOOL) filter{
    
    int count = 0;
    
    // Add features
    NSMutableDictionary * featureTables = [[NSMutableDictionary alloc] init];
    if(self.editFeaturesMode){
        NSMutableArray * databaseFeatures = [[NSMutableArray alloc] init];
        [databaseFeatures addObject:self.editFeaturesTable];
        [featureTables setObject:databaseFeatures forKey:self.editFeaturesDatabase];
        GPKGGeoPackage *geoPackage = [self.geoPackages getOrOpen:self.editFeaturesDatabase];
        NSMutableDictionary * databaseFeatureDaos = [self.featureDaos objectForKey:self.editFeaturesDatabase];
        if(databaseFeatureDaos == nil){
            databaseFeatureDaos = [[NSMutableDictionary alloc] init];
            [self.featureDaos setObject:databaseFeatureDaos forKey:self.editFeaturesDatabase];
        }
        GPKGFeatureDao * featureDao = [databaseFeatureDaos objectForKey:self.editFeaturesTable];
        if(featureDao == nil){
            featureDao = [geoPackage getFeatureDaoWithTableName:self.editFeaturesTable];
            [databaseFeatureDaos setObject:featureDao forKey:self.editFeaturesTable];
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
        
        if([self.geoPackages has:databaseName]){
        
            NSMutableArray * databaseFeatures = [featureTables objectForKey:databaseName];
            
            for(NSString * features in databaseFeatures){
                
                if([[self.featureDaos objectForKey:databaseName] objectForKey:features] != nil){
                
                    count = [self displayFeaturesWithId:updateId andDatabase:databaseName andFeatures:features andCount:count andMaxFeatures:maxFeatures andEditable:self.editFeaturesMode andMapViewBoundingBox:mapViewBoundingBox andToleranceDistance:toleranceDistance andFilter:filter];
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
            
            if(ignoreChange){
                self.ignoreRegionChange = true;
            }
            [self.mapView setRegion:expandedRegion animated:true];
        }
    }
}

-(void) displayTiles: (GPKGSTileTable *) tiles{
    
    GPKGGeoPackage *geoPackage = [self.geoPackages getOrOpen:tiles.database];
    
    GPKGTileDao * tileDao = [geoPackage getTileDaoWithTableName:tiles.name];
    
    GPKGTileTableScaling *tileTableScaling = [[GPKGTileTableScaling alloc] initWithGeoPackage:geoPackage andTileDao:tileDao];
    GPKGTileScaling *tileScaling = [tileTableScaling get];
    
    GPKGBoundedOverlay * overlay = [GPKGOverlayFactory boundedOverlay:tileDao andScaling:tileScaling];
    overlay.canReplaceMapContent = false;
    
    GPKGTileMatrixSet * tileMatrixSet = tileDao.tileMatrixSet;
    
    GPKGFeatureTileTableLinker * linker = [[GPKGFeatureTileTableLinker alloc] initWithGeoPackage:geoPackage];
    NSArray<GPKGFeatureDao *> * featureDaos = [linker getFeatureDaosForTileTable:tileDao.tableName];
    for(GPKGFeatureDao * featureDao in featureDaos){
        
        // Create the feature tiles
        GPKGFeatureTiles * featureTiles = [[GPKGFeatureTiles alloc] initWithFeatureDao:featureDao];
        
        // Create an index manager
        GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
        [featureTiles setIndexManager:indexer];
        
        self.featureOverlayTiles = true;
        
        // Add the feature overlay query
        GPKGFeatureOverlayQuery * featureOverlayQuery = [[GPKGFeatureOverlayQuery alloc] initWithBoundedOverlay:overlay andFeatureTiles:featureTiles];
        [self.featureOverlayQueries addObject:featureOverlayQuery];
    }
    
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
        displayBoundingBox = [displayBoundingBox overlap:transformedContentsBoundingBox];
    }
    
    [self displayTilesWithOverlay:overlay andBoundingBox:displayBoundingBox andSrs:tileMatrixSetSrs andSpecifiedBoundingBox:nil];
}

-(void) displayFeatureTiles: (GPKGSFeatureOverlayTable *) featureOverlayTable{
    
    GPKGGeoPackage *geoPackage = [self.geoPackages getOrOpen:featureOverlayTable.database];
    
    GPKGFeatureDao * featureDao = [[self.featureDaos objectForKey:featureOverlayTable.database] objectForKey:featureOverlayTable.featureTable];
    
    GPKGBoundingBox * boundingBox = [[GPKGBoundingBox alloc] initWithMinLongitudeDouble:featureOverlayTable.minLon andMinLatitudeDouble:featureOverlayTable.minLat andMaxLongitudeDouble:featureOverlayTable.maxLon andMaxLatitudeDouble:featureOverlayTable.maxLat];
    
    // Load tiles
    GPKGFeatureTiles * featureTiles = [[GPKGFeatureTiles alloc] initWithFeatureDao:featureDao];
    
    [featureTiles setMaxFeaturesPerTile:featureOverlayTable.maxFeaturesPerTile];
    if(featureOverlayTable.maxFeaturesPerTile != nil){
        [featureTiles setMaxFeaturesTileDraw:[[GPKGNumberFeaturesTile alloc] init]];
    }
    
    GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
    [featureTiles setIndexManager:indexer];
    
    [featureTiles setPointColor:featureOverlayTable.pointColor];
    [featureTiles setPointRadius:featureOverlayTable.pointRadius];
    [featureTiles setLineColor:featureOverlayTable.lineColor];
    [featureTiles setLineStrokeWidth:featureOverlayTable.lineStroke];
    [featureTiles setPolygonColor:featureOverlayTable.polygonColor];
    [featureTiles setPolygonStrokeWidth:featureOverlayTable.polygonStroke];
    [featureTiles setFillPolygon:featureOverlayTable.polygonFill];
    if(featureTiles.fillPolygon){
        [featureTiles setPolygonFillColor:featureOverlayTable.polygonFillColor];
    }
    
    [featureTiles calculateDrawOverlap];
    
    GPKGFeatureOverlay * featureOverlay = [[GPKGFeatureOverlay alloc] initWithFeatureTiles:featureTiles];
    boundingBox = [GPKGTileBoundingBoxUtils boundWgs84BoundingBoxWithWebMercatorLimits:boundingBox];
    [featureOverlay setBoundingBox:boundingBox withProjection:[SFPProjectionFactory projectionWithEpsgInt:PROJ_EPSG_WORLD_GEODETIC_SYSTEM]];
    [featureOverlay setMinZoom:[NSNumber numberWithInt:featureOverlayTable.minZoom]];
    [featureOverlay setMaxZoom:[NSNumber numberWithInt:featureOverlayTable.maxZoom]];
    
    // Get the tile linked overlay
    GPKGBoundedOverlay *overlay = [GPKGOverlayFactory linkedFeatureOverlayWithOverlay:featureOverlay andGeoPackage:geoPackage];
    
    GPKGGeometryColumns * geometryColumns = featureDao.geometryColumns;
    GPKGContents * contents = [[geoPackage getGeometryColumnsDao] getContents:geometryColumns];
    
    self.featureOverlayTiles = true;
    
    GPKGFeatureOverlayQuery * featureOverlayQuery = [[GPKGFeatureOverlayQuery alloc] initWithBoundedOverlay:overlay andFeatureTiles:featureTiles];
    [self.featureOverlayQueries addObject:featureOverlayQuery];
    
    GPKGContentsDao * contentsDao = [geoPackage getContentsDao];
    [self displayTilesWithOverlay:overlay andBoundingBox:[contents getBoundingBox] andSrs:[contentsDao getSrs:contents] andSpecifiedBoundingBox:boundingBox];
}

-(void) displayTilesWithOverlay: (MKTileOverlay *) overlay andBoundingBox: (GPKGBoundingBox *) dataBoundingBox andSrs: (GPKGSpatialReferenceSystem *) srs andSpecifiedBoundingBox: (GPKGBoundingBox *) specifiedBoundingBox{
    
    GPKGBoundingBox * boundingBox = dataBoundingBox;
    if(boundingBox != nil){
        boundingBox = [self transformBoundingBoxToWgs84:boundingBox withSrs:srs];
    }else{
        boundingBox = [[GPKGBoundingBox alloc] initWithMinLongitudeDouble:-PROJ_WGS84_HALF_WORLD_LON_WIDTH andMinLatitudeDouble:PROJ_WEB_MERCATOR_MIN_LAT_RANGE andMaxLongitudeDouble:PROJ_WGS84_HALF_WORLD_LON_WIDTH andMaxLatitudeDouble:PROJ_WEB_MERCATOR_MAX_LAT_RANGE];
    }
    
    if(specifiedBoundingBox != nil){
        boundingBox = [boundingBox overlap:specifiedBoundingBox];
    }
    
    if(self.tilesBoundingBox == nil){
        self.tilesBoundingBox = boundingBox;
    }else{
        self.tilesBoundingBox = [self.tilesBoundingBox union:boundingBox];
    }
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        [self.mapView addOverlay:overlay];
    });
}

-(int) displayFeaturesWithId: (int) updateId andDatabase: (NSString *) database andFeatures: (NSString *) features andCount: (int) count andMaxFeatures: (int) maxFeatures andEditable: (BOOL) editable andMapViewBoundingBox: (GPKGBoundingBox *) mapViewBoundingBox andToleranceDistance: (double) toleranceDistance andFilter: (BOOL) filter{
    
    GPKGGeoPackage * geoPackage = [self.geoPackages getOrOpen:database];
    GPKGFeatureDao * featureDao = [[self.featureDaos objectForKey:database] objectForKey:features];
    NSString * tableName = featureDao.tableName;
    GPKGMapShapeConverter * converter = [[GPKGMapShapeConverter alloc] initWithProjection:featureDao.projection];
    
    [converter setSimplifyToleranceAsDouble:toleranceDistance];
    
    count += [self.featureShapes featureIdsCountInDatabase:database withTable:tableName];
    
    if(![self featureUpdateCanceled:updateId] && count < maxFeatures){
    
        SFPProjection *mapViewProjection = [SFPProjectionFactory projectionWithEpsgInt: PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
        
        GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
        @try{
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
        }@finally{
            [indexer close];
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
                    if(self.editFeaturesMode){
                        GPKGMapPoint *mapPoint = [self addEditableShapeWithFeatureId:featureId andShape:mapShape];
                        if(mapPoint != nil){
                            GPKGMapShape *mapPointShape = [[GPKGMapShape alloc] initWithGeometryType:SF_POINT andShapeType:GPKG_MST_POINT andShape:mapPoint];
                            [self.featureShapes addMapShape:mapPointShape withFeatureId:featureId toDatabase:database withTable:tableName];
                        }
                    }else{
                        [self addMapPointShapeWithFeatureId:[featureId intValue] andDatabase:database andTableName:tableName andMapShape:mapShape];
                    }
                    [self.featureShapes addMapShape:mapShape withFeatureId:featureId toDatabase:database withTable:tableName];
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
            [mapPoint.options setPinTintColor:[UIColor greenColor]];
        }else{
            [mapPoint.options setPinTintColor:[UIColor purpleColor]];
        }
    }else{
        [mapPoint.options setPinTintColor:[UIColor purpleColor]];
    }
    
}

-(GPKGMapPoint *) addEditableShapeWithFeatureId: (NSNumber *) featureId andShape: (GPKGMapShape *) shape{
    
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
    
    return mapPoint;
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
        [self updateInBackgroundWithZoom:false andFilter:true];
        
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
            displayTextViewController.mapPoint = mapPoint;
        }
    }
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
    GPKGBoundingBox * bbox = [[GPKGBoundingBox alloc]initWithMinLongitudeDouble:minLon andMinLatitudeDouble:minLat andMaxLongitudeDouble:maxLon andMaxLatitudeDouble:maxLat];
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
