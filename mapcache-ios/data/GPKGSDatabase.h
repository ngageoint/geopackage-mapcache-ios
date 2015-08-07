//
//  GPKGSDatabase.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "GPKGSTable.h"

@interface GPKGSDatabase : NSObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic) BOOL expanded;

-(instancetype) initWithName: (NSString *) name andExpanded: (BOOL) expanded;

-(NSArray *) getFeatures;

-(NSInteger) getFeatureCount;

-(NSArray *) getFeatureOverlays;

-(NSInteger) getFeatureOverlayCount;

-(NSInteger) getActiveFeatureOverlayCount;

-(NSArray *) getTiles;

-(NSInteger) getTileCount;

-(NSArray *) getTables;

-(NSInteger) getTableCount;

-(NSInteger) getActiveTableCount;

-(void) addFeature: (GPKGSTable *) table;

-(void) addFeatureOverlay: (GPKGSTable *) table;

-(void) addTile: (GPKGSTable *) table;

-(BOOL) exists: (GPKGSTable *) table;

-(void) add:(GPKGSTable *) table;

-(void) remove:(GPKGSTable *) table;

-(BOOL) isEmpty;

@end
