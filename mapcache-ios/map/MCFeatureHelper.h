//
//  MCFeatureHelper.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/19/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SFPProjectionFactory.h"
#import "SFGeometryEnvelopeBuilder.h"
#import "SFPProjectionConstants.h"
#import "GPKGBoundingBox.h"
#import "GPKGMapPoint.h"
#import "GPKGMultiPoint.h"
#import "GPKGMapShape.h"
#import "GPKGGeometryData.h"
#import "GPKGFeatureRow.h"
#import "GPKGTileBoundingBoxUtils.h"
#import "GPKGMapShapeConverter.h"
#import "GPKGFeatureShapes.h"
#import "GPKGGeoPackageManager.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGFeatureIndexManager.h"
#import "GPKGFeatureIndexResults.h"
#import "GPKGMultipleFeatureIndexResults.h"
#import "GPKGSDatabase.h"
#import "GPKGSDatabases.h"
#import "GPKGGeoPackage.h"
#import "GPKGSMapPointData.h"


@protocol MCFeatureHelperDelegate <NSObject>
- (void) addShapeToMapView:(GPKGMapShape *) shape withCount:(int) count;
@end


@interface MCFeatureHelper : NSObject
@property (nonatomic, strong) id<MCFeatureHelperDelegate> featureHelperDelegate;
@property (atomic) int featureUpdateCountId;
@property (nonatomic, strong) GPKGFeatureShapes * featureShapes;

- (instancetype) initWithFeatureHelperDelegate:(id<MCFeatureHelperDelegate>) delegate;

- (void)prepareFeaturesWithUpdateId:(int) updateId andFeatureUpdateId:(int) featureUpdateId andZoom:(int) zoom andMaxFeatures:(int) maxFeatures andMapViewBoundingBox:(GPKGBoundingBox *) mapViewBoudingBox andToleranceDistance:(double) toleranceDistance andFilter:(BOOL) filter;

-(void) addMapPointShapeWithFeatureId: (int) featureId andDatabase: (NSString *) database andTableName: (NSString *) tableName andMapShape: (GPKGMapShape *) shape;

-(void) setTitleWithMapPoint: (GPKGMapPoint *) mapPoint;

-(void) setShapeOptionsWithMapPoint: (GPKGMapPoint *) mapPoint andEditable: (BOOL) editable andClickable: (BOOL) clickable;

-(void) prepareShapeOptionsWithShape: (GPKGMapShape *) shape andEditable: (BOOL) editable andTopLevel: (BOOL) topLevel;

-(GPKGMapShape *) processFeatureRow: (GPKGFeatureRow *) row WithDatabase: (NSString *) database andTableName: (NSString *) tableName andConverter: (GPKGMapShapeConverter *) converter andCount: (int) count andMaxFeatures: (int) maxFeatures andEditable: (BOOL) editable andFilterBoundingBox: (GPKGBoundingBox *) boundingBox andFilterMaxLongitude: (double) maxLongitude andFilter: (BOOL) filter;

@end

