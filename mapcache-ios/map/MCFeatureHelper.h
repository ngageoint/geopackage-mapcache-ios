//
//  MCFeatureHelper.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/19/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPKGBoundingBox.h"
#import "GPKGSMapPointData.h"
#import "GPKGMapPoint.h"
#import "GPKGMultiPoint.h"
#import "GPKGMapShape.h"
#import "SFGeometryEnvelopeBuilder.h"
#import "GPKGGeometryData.h"
#import "GPKGFeatureRow.h"
#import "SFPProjectionFactory.h"
#import "GPKGTileBoundingBoxUtils.h"
#import "GPKGMapShapeConverter.h"
#import "GPKGFeatureShapes.h"


@protocol MCFeatureHelperDelegate <NSObject>
- (void) addShapeToMapView: (GPKGMapShape *) shape;
@end


@interface MCFeatureHelper : NSObject
@property (nonatomic, strong) GPKGFeatureShapes * featureShapes;


-(void) addMapPointShapeWithFeatureId: (int) featureId andDatabase: (NSString *) database andTableName: (NSString *) tableName andMapShape: (GPKGMapShape *) shape;
-(void) setTitleWithMapPoint: (GPKGMapPoint *) mapPoint;
-(void) setShapeOptionsWithMapPoint: (GPKGMapPoint *) mapPoint andEditable: (BOOL) editable andClickable: (BOOL) clickable;
-(void) prepareShapeOptionsWithShape: (GPKGMapShape *) shape andEditable: (BOOL) editable andTopLevel: (BOOL) topLevel;
-(GPKGMapShape *) processFeatureRow: (GPKGFeatureRow *) row WithDatabase: (NSString *) database andTableName: (NSString *) tableName andConverter: (GPKGMapShapeConverter *) converter andCount: (int) count andMaxFeatures: (int) maxFeatures andEditable: (BOOL) editable andFilterBoundingBox: (GPKGBoundingBox *) boundingBox andFilterMaxLongitude: (double) maxLongitude andFilter: (BOOL) filter;

@end

