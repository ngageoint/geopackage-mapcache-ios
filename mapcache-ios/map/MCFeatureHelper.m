//
//  MCFeatureHelper.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/19/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCFeatureHelper.h"

@interface MCFeatureHelper ()
@property (nonatomic, strong) GPKGBoundingBox *featuresBoundingBox;
@property (nonatomic, strong) NSNumberFormatter *locationDecimalFormatter;
@end


@implementation MCFeatureHelper

- (instancetype) init {
    self = [super init];
    
    self.featuresBoundingBox = nil;
    self.featureShapes = [[GPKGFeatureShapes alloc] init];
    self.locationDecimalFormatter = [[NSNumberFormatter alloc] init];
    self.locationDecimalFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    self.locationDecimalFormatter.maximumFractionDigits = 4;
    
    return self;
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


-(void) setShapeOptionsWithMapPoint: (GPKGMapPoint *) mapPoint andEditable: (BOOL) editable andClickable: (BOOL) clickable {
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


-(void) prepareShapeOptionsWithShape: (GPKGMapShape *) shape andEditable: (BOOL) editable andTopLevel: (BOOL) topLevel {
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


-(GPKGMapShape *) processFeatureRow: (GPKGFeatureRow *) row WithDatabase: (NSString *) database andTableName: (NSString *) tableName andConverter: (GPKGMapShapeConverter *) converter andCount: (int) count andMaxFeatures: (int) maxFeatures andEditable: (BOOL) editable andFilterBoundingBox: (GPKGBoundingBox *) boundingBox andFilterMaxLongitude: (double) maxLongitude andFilter: (BOOL) filter {
    
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
            
            if(passesFilter){
                NSNumber * featureId = [row getId];
                GPKGMapShape * shape = [converter toShapeWithGeometry:geometry];
                [self updateFeaturesBoundingBox:shape];
                [self prepareShapeOptionsWithShape:shape andEditable:editable andTopLevel:true];
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
