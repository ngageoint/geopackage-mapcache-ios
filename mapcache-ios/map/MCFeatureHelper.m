//
//  MCFeatureHelper.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/19/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCFeatureHelper.h"
#import "MCColorUtil.h"

@interface MCFeatureHelper ()
@property (nonatomic, strong) GPKGBoundingBox *featuresBoundingBox;
@property (nonatomic, strong) NSNumberFormatter *locationDecimalFormatter;
@property (nonatomic, strong) GPKGSDatabases *active;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) NSMutableDictionary *geoPackages;
@property (nonatomic, strong) NSMutableDictionary *featureDaos;
@end


@implementation MCFeatureHelper

- (instancetype) initWithFeatureHelperDelegate:(id<MCFeatureHelperDelegate>) delegate {
    self = [super init];
    
    self.featureHelperDelegate = delegate;
    self.featuresBoundingBox = nil;
    self.featureShapes = [[GPKGFeatureShapes alloc] init];
    self.locationDecimalFormatter = [[NSNumberFormatter alloc] init];
    self.locationDecimalFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    self.locationDecimalFormatter.maximumFractionDigits = 4;
    self.active = [GPKGSDatabases getInstance];
    self.manager = [GPKGGeoPackageFactory manager];
    self.geoPackages = [[NSMutableDictionary alloc] init];
    self.featureDaos = [[NSMutableDictionary alloc] init];
    self.featureUpdateCountId = 0;
    self.updateCountId = 0;
    self.featureCount = 0;
    return self;
}


// Helper version of updateWithID...
- (void)prepareFeaturesWithUpdateId:(int) updateId andFeatureUpdateId:(int) featureUpdateId andZoom:(int) zoom andMaxFeatures:(int) maxFeatures andMapViewBoundingBox:(GPKGBoundingBox *) mapViewBoundingBox andToleranceDistance:(double) toleranceDistance andFilter:(BOOL) filter {

    int count = 0;
    
    NSArray * activeDatabases = [[NSArray alloc] initWithArray:[self.active getDatabases]];
    
    // Open active GeoPackages and create feature DAOS, and feature tiles
    for(GPKGSDatabase * database in activeDatabases){
        
        if([self updateCanceled:updateId]){
            break;
        }
        
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
            
            if(featureTableDaos.count > 0){
                NSMutableDictionary * databaseFeatureDaos = [[NSMutableDictionary alloc] init];
                [self.featureDaos setObject:databaseFeatureDaos forKey:database.name];
                for(NSString *featureTable in featureTableDaos){
                    GPKGFeatureDao * featureDao = [geoPackage featureDaoWithTableName:featureTable];
                    [databaseFeatureDaos setObject:featureDao forKey:featureTable];
                }
            }
        } else{
            [self.active removeDatabase:database.name andPreserveOverlays:false];
        }
    }
    
    count = [self addFeaturesWithId:featureUpdateId andMaxFeatures:maxFeatures andMapViewBoundingBox:mapViewBoundingBox andToleranceDistance:toleranceDistance andFilter:filter];
}


- (void)prepareFeaturesWithGeoPackage:(GPKGGeoPackage *) geoPackage andDatabase:(GPKGSDatabase *) database andUpdateId:(int) updateId andFeatureUpdateId:(int) featureUpdateId andZoom:(int) zoom andMaxFeatures:(int) maxFeatures andMapViewBoundingBox:(GPKGBoundingBox *) mapViewBoundingBox andToleranceDistance:(double) toleranceDistance andFilter:(BOOL) filter {

    if([self updateCanceled:updateId]){
        return;
    }
    
    if(geoPackage != nil){
        [self.geoPackages setObject:geoPackage forKey:database.name];
        
        NSMutableSet * featureTableDaos = [[NSMutableSet alloc] init];
        NSArray * features = [database getFeatures];
        if([features count] > 0){
            for(GPKGSTable * features in [database getFeatures]){
                [featureTableDaos addObject:features.name];
            }
        }
        
        if(featureTableDaos.count > 0){
            NSMutableDictionary * databaseFeatureDaos = [[NSMutableDictionary alloc] init];
            [self.featureDaos setObject:databaseFeatureDaos forKey:database.name];
            for(NSString *featureTable in featureTableDaos){
                GPKGFeatureDao * featureDao = [geoPackage featureDaoWithTableName:featureTable];
                [databaseFeatureDaos setObject:featureDao forKey:featureTable];
            }
        }
    } else{
        [self.active removeDatabase:database.name andPreserveOverlays:false];
    }
    
    [self addFeaturesWithId:featureUpdateId andMaxFeatures:maxFeatures andMapViewBoundingBox:mapViewBoundingBox andToleranceDistance:toleranceDistance andFilter:filter];
}


-(int) addFeaturesWithId: (int) updateId andMaxFeatures: (int) maxFeatures andMapViewBoundingBox: (GPKGBoundingBox *) mapViewBoundingBox andToleranceDistance: (double) toleranceDistance andFilter: (BOOL) filter {
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
        
        if(self.featureCount >= maxFeatures){
            break;
        }
        
        if([self.geoPackages objectForKey:databaseName] != nil){
            
            NSMutableArray * databaseFeatures = [featureTables objectForKey:databaseName];
            
            GPKGGeoPackage *geoPackage = [self.geoPackages objectForKey:databaseName];
            GPKGStyleCache *styleCache = [[GPKGStyleCache alloc] initWithGeoPackage:geoPackage];
            
            for(NSString * features in databaseFeatures){
                
                if([[self.featureDaos objectForKey:databaseName] objectForKey:features] != nil){
                    
                    self.featureCount = [self displayFeaturesWithId:updateId andGeoPackage:geoPackage andStyleCache:styleCache andFeatures:features andCount:self.featureCount andMaxFeatures:maxFeatures andEditable:NO andMapViewBoundingBox:mapViewBoundingBox andToleranceDistance:toleranceDistance andFilter:filter];
                    if([self featureUpdateCanceled:updateId]){
                        break;
                    } else if (self.featureCount >= maxFeatures) {
                        [self.featureHelperDelegate showMaxFeaturesWarning];
                        break;
                    }
                }
            }
            
            [styleCache clear];
        }
        
        if([self featureUpdateCanceled:updateId]){
            break;
        }
    }
    
    return self.featureCount;
}


-(int) displayFeaturesWithId: (int) updateId andGeoPackage: (GPKGGeoPackage *) geoPackage andStyleCache: (GPKGStyleCache *) styleCache andFeatures: (NSString *) features andCount: (int) count andMaxFeatures: (int) maxFeatures andEditable: (BOOL) editable andMapViewBoundingBox: (GPKGBoundingBox *) mapViewBoundingBox andToleranceDistance: (double) toleranceDistance andFilter: (BOOL) filter{
    
    NSString *database = geoPackage.name;
    GPKGFeatureDao * featureDao = [[self.featureDaos objectForKey:database] objectForKey:features];
    NSString * tableName = featureDao.tableName;
    GPKGMapShapeConverter * converter = [[GPKGMapShapeConverter alloc] initWithProjection:featureDao.projection];
    
    [converter setSimplifyToleranceAsDouble:toleranceDistance];
    
    if(![[styleCache featureStyleExtension] hasWithTable:features]){
        styleCache = nil;
    }
    
    count += [self.featureShapes featureIdsCountInDatabase:database withTable:tableName];
    
    if(![self featureUpdateCanceled:updateId] && count < maxFeatures){
        
        SFPProjection *mapViewProjection = [SFPProjectionFactory projectionWithEpsgInt: PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
        
        NSArray<NSString *> *columns = [featureDao idAndGeometryColumnNames];
        
        GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
        if(filter && [indexer isIndexed]){
            
            GPKGFeatureIndexResults *indexResults = [indexer queryWithColumns:columns andBoundingBox:mapViewBoundingBox inProjection:mapViewProjection];
            GPKGBoundingBox *complementary = [mapViewBoundingBox complementaryWgs84];
            if(complementary != nil){
                GPKGFeatureIndexResults *indexResults2 = [indexer queryWithColumns:columns andBoundingBox:complementary inProjection:mapViewProjection];
                indexResults = [[GPKGMultipleFeatureIndexResults alloc] initWithFeatureIndexResults1:indexResults andFeatureIndexResults2:indexResults2];
            }
            count = [self processFeatureIndexResults:indexResults withUpdateId:updateId andDatabase:database andCount:count andMaxFeatures:maxFeatures andEditable:editable andTableName:tableName andConverter:converter andStyleCache:styleCache andFilter:filter];
            
        }else{
            
            GPKGBoundingBox *filterBoundingBox = nil;
            double filterMaxLongitude = 0;
            
            if(filter){
                SFPProjection *featureProjection = featureDao.projection;
                SFPProjectionTransform * projectionTransform = [[SFPProjectionTransform alloc] initWithFromProjection:mapViewProjection andToProjection:featureProjection];
                GPKGBoundingBox *boundedMapViewBoundingBox = [mapViewBoundingBox boundWgs84Coordinates];
                GPKGBoundingBox *transformedBoundingBox = [boundedMapViewBoundingBox transform:projectionTransform];
                if([featureProjection isUnit:SFP_UNIT_DEGREES]){
                    filterMaxLongitude = PROJ_WGS84_HALF_WORLD_LON_WIDTH;
                }else if([featureProjection isUnit:SFP_UNIT_METERS]){
                    filterMaxLongitude = PROJ_WEB_MERCATOR_HALF_WORLD_WIDTH;
                }
                filterBoundingBox = [transformedBoundingBox expandCoordinatesWithMaxLongitude:filterMaxLongitude];
            }
            
            // Query for all rows
            GPKGResultSet * results = [featureDao queryWithColumns:columns];
            @try {
                while(![self featureUpdateCanceled:updateId] && count < maxFeatures && [results moveToNext]){
                    @try {
                        GPKGFeatureRow * row = [featureDao featureRow:results];
                        GPKGMapShape *shape = [self processFeatureRow:row WithDatabase:database andTableName:tableName andConverter:converter andStyleCache:styleCache andCount:count andMaxFeatures:maxFeatures andEditable:editable andFilterBoundingBox:filterBoundingBox andFilterMaxLongitude:filterMaxLongitude andFilter:filter];
                        
                        if (shape != nil && count++ < maxFeatures) {
                            [self.featureHelperDelegate addShapeToMapView:shape withCount:count];
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


-(int) processFeatureIndexResults: (GPKGFeatureIndexResults *) indexResults withUpdateId: (int) updateId andDatabase: (NSString *) database andCount: (int) count andMaxFeatures: (int) maxFeatures andEditable: (BOOL) editable andTableName: (NSString *) tableName andConverter: (GPKGMapShapeConverter *) converter andStyleCache: (GPKGStyleCache *) styleCache andFilter: (BOOL) filter{
    
    @try {
        for(GPKGFeatureRow *row in indexResults){
            
            if([self featureUpdateCanceled:updateId] || count >= maxFeatures){
                break;
            }
            
            if(![self.featureShapes existsWithFeatureId:[row id] inDatabase:database withTable:tableName]){
                GPKGMapShape *shape = [self processFeatureRow:row WithDatabase:database andTableName:tableName andConverter:converter andStyleCache:styleCache andCount:count andMaxFeatures:maxFeatures andEditable:editable andFilterBoundingBox:nil andFilterMaxLongitude:0 andFilter:filter];
                
                if (shape != nil && count++ < maxFeatures) {
                    [self.featureHelperDelegate addShapeToMapView:shape withCount:count];
                }
            }
        }
    }
    @finally {
        [indexResults close];
    }
    
    return count;
}


- (void) resetFeatureCount {
    self.featureCount = 0;
}


- (int)getNewUpdateId {
    return ++self.updateCountId;
}


- (int)getNewFeatureUpdateId {
    return ++self.featureUpdateCountId;
}


- (BOOL)featureUpdateCanceled: (int) updateId {
    BOOL canceled = updateId < self.featureUpdateCountId;
    return canceled;
}


-(BOOL) updateCanceled: (int) updateId{
    BOOL canceled = updateId < self.updateCountId;
    return canceled;
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


-(NSString *) buildLocationTitleWithMapPoint: (GPKGMapPoint *) mapPoint{
    CLLocationCoordinate2D coordinate = mapPoint.coordinate;
    NSString *lat = [self.locationDecimalFormatter stringFromNumber:[NSNumber numberWithDouble:coordinate.latitude]];
    NSString *lon = [self.locationDecimalFormatter stringFromNumber:[NSNumber numberWithDouble:coordinate.longitude]];
    NSString * title = [NSString stringWithFormat:@"(lat=%@, lon=%@)", lat, lon];
    
    return title;
}


-(GPKGSMapPointData *) getOrCreateDataWithMapPoint: (GPKGMapPoint *) mapPoint{
    if(mapPoint.data == nil){
        mapPoint.data = [[GPKGSMapPointData alloc] init];
    }
    return (GPKGSMapPointData *) mapPoint.data;
}


-(void) setShapeOptionsWithMapPoint: (GPKGMapPoint *) mapPoint andStyleCache: (GPKGStyleCache *) styleCache andFeatureStyle: (GPKGFeatureStyle *) featureStyle andEditable: (BOOL) editable andClickable: (BOOL) clickable {
    if(editable){
        if(clickable){
            [mapPoint.options setPinTintColor:[UIColor greenColor]];
        }else{
            [mapPoint.options setPinTintColor:[UIColor purpleColor]];
        }
    }else if(styleCache == nil || ![styleCache setFeatureStyleWithMapPoint:mapPoint andFeatureStyle:featureStyle]){
        [mapPoint.options setPinTintColor:[UIColor redColor]];
    }
}


-(void) setShapeOptionsWithPolyline: (GPKGPolyline *) polyline andStyleCache: (GPKGStyleCache *) styleCache andFeatureStyle: (GPKGFeatureStyle *) featureStyle andEditable: (BOOL) editable{
    
    if(editable){
        // TODO editable style options
        GPKGPolylineOptions *options = [[GPKGPolylineOptions alloc] init];
        [options setStrokeColor:[MCColorUtil getPolygonStrokeColor]]; // TODO Polyline stroke color?
        [options setLineWidth:2.0];
        [polyline setOptions:options];
    }else if(styleCache == nil || ![styleCache setFeatureStyleWithPolyline:polyline andFeatureStyle:featureStyle]){
        GPKGPolylineOptions *options = [[GPKGPolylineOptions alloc] init];
        [options setStrokeColor:[MCColorUtil getPolygonStrokeColor]]; // TODO Polyline stroke color?
        [options setLineWidth:2.0];
        [polyline setOptions:options];
    }
    
}


-(void) setShapeOptionsWithPolygon: (GPKGPolygon *) polygon andStyleCache: (GPKGStyleCache *) styleCache andFeatureStyle: (GPKGFeatureStyle *) featureStyle andEditable: (BOOL) editable{
    
    if(editable){
        // TODO editable style options
        GPKGPolygonOptions *options = [[GPKGPolygonOptions alloc] init];
        [options setStrokeColor:[MCColorUtil getPolygonStrokeColor]];
        [options setLineWidth:2.0];
        [options setFillColor:[MCColorUtil getPolygonFillColor]];
        [polygon setOptions:options];
    }else if(styleCache == nil || ![styleCache setFeatureStyleWithPolygon:polygon andFeatureStyle:featureStyle]){
        GPKGPolygonOptions *options = [[GPKGPolygonOptions alloc] init];
        [options setStrokeColor:[MCColorUtil getPolygonStrokeColor]];
        [options setLineWidth:2.0];
        [options setFillColor:[MCColorUtil getPolygonFillColor]];
        [polygon setOptions:options];
    }
    
}


-(void) prepareShapeOptionsWithShape: (GPKGMapShape *) shape andStyleCache: (GPKGStyleCache *) styleCache andFeature: (GPKGFeatureRow *) featureRow andEditable: (BOOL) editable andTopLevel: (BOOL) topLevel {

    GPKGFeatureStyle *featureStyle = nil;
    if (styleCache != nil) {
        featureStyle = [[styleCache featureStyleExtension] featureStyleWithFeature:featureRow andGeometryType:shape.geometryType];
    }

    switch(shape.shapeType){
        case GPKG_MST_POINT:
        {
            GPKGMapPoint * mapPoint = (GPKGMapPoint *) shape.shape;
            [self setShapeOptionsWithMapPoint:mapPoint andStyleCache:styleCache andFeatureStyle:featureStyle andEditable:editable andClickable:topLevel];
        }
            break;
            
        case GPKG_MST_POLYLINE:
        {
            GPKGPolyline *polyline = (GPKGPolyline *) shape.shape;
            [self setShapeOptionsWithPolyline:polyline andStyleCache:styleCache andFeatureStyle:featureStyle andEditable:editable];
        }
            break;
            
        case GPKG_MST_POLYGON:
        {
            GPKGPolygon *polygon = (GPKGPolygon *) shape.shape;
            [self setShapeOptionsWithPolygon:polygon andStyleCache:styleCache andFeatureStyle:featureStyle andEditable:editable];
        }
            break;
            
        case GPKG_MST_MULTI_POINT:
        {
            GPKGMultiPoint * multiPoint = (GPKGMultiPoint *) shape.shape;
            for(GPKGMapPoint * mapPoint in multiPoint.points){
                [self setShapeOptionsWithMapPoint:mapPoint andStyleCache:styleCache andFeatureStyle:featureStyle andEditable:editable andClickable:false];
            }
        }
            break;
            
        case GPKG_MST_MULTI_POLYLINE:
        {
            GPKGMultiPolyline *multiPolyline = (GPKGMultiPolyline *) shape.shape;
            for(GPKGPolyline *polyline in multiPolyline.polylines){
                [self setShapeOptionsWithPolyline:polyline andStyleCache:styleCache andFeatureStyle:featureStyle andEditable:editable];
            }
        }
            break;
            
        case GPKG_MST_MULTI_POLYGON:
        {
            GPKGMultiPolygon *multiPolygon = (GPKGMultiPolygon *) shape.shape;
            for(GPKGPolygon *polygon in multiPolygon.polygons){
                [self setShapeOptionsWithPolygon:polygon andStyleCache:styleCache andFeatureStyle:featureStyle andEditable:editable];
            }
        }
            break;
            
        case GPKG_MST_COLLECTION:
        {
            NSArray * shapeArray = (NSArray *) shape.shape;
            for(GPKGMapShape * shape in shapeArray){
                [self prepareShapeOptionsWithShape:shape andStyleCache:styleCache andFeature:featureRow andEditable:editable andTopLevel:false];
            }
        }
            break;
            
        default:
            
            break;
    }
    
}


-(GPKGMapShape *) processFeatureRow: (GPKGFeatureRow *) row WithDatabase: (NSString *) database andTableName: (NSString *) tableName andConverter: (GPKGMapShapeConverter *) converter andStyleCache: (GPKGStyleCache *) styleCache andCount: (int) count andMaxFeatures: (int) maxFeatures andEditable: (BOOL) editable andFilterBoundingBox: (GPKGBoundingBox *) boundingBox andFilterMaxLongitude: (double) maxLongitude andFilter: (BOOL) filter {
    
    GPKGGeometryData * geometryData = [row geometry];
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
                        GPKGBoundingBox *geometryBoundingBox = [[GPKGBoundingBox alloc] initWithEnvelope:envelope];
                        passesFilter = [GPKGTileBoundingBoxUtils overlapWithBoundingBox:boundingBox andBoundingBox:geometryBoundingBox withMaxLongitude:maxLongitude] != nil;
                    }
                }
            }
            
            if(passesFilter){
                NSNumber * featureId = [row id];
                GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                [self updateFeaturesBoundingBox:shape];
                [self prepareShapeOptionsWithShape:shape andStyleCache:styleCache andFeature:row andEditable:editable andTopLevel:true];
                [self addMapPointShapeWithFeatureId:[featureId intValue] andDatabase:database andTableName:tableName andMapShape:shape];
                [self.featureShapes addMapShape:shape withFeatureId:featureId toDatabase:database withTable:tableName];
                
                return shape;
            }
        }
    }
    
    return nil;
}


-(void) updateFeaturesBoundingBox: (GPKGMapShape *) shape {
    if(self.featuresBoundingBox != nil){
        [shape expandBoundingBox:self.featuresBoundingBox];
    }else{
        self.featuresBoundingBox = [shape boundingBox];
    }
}


@end
