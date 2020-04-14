//
//  GPKGSDatabase.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCTable.h"

@interface MCDatabase : NSObject

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

-(void) addFeature: (MCTable *) table;

-(void) addFeatureOverlay: (MCTable *) table;

-(void) addTile: (MCTable *) table;

-(BOOL) exists: (MCTable *) table;

- (BOOL) hasTableNamed:(NSString *)tableName;

-(BOOL) existsWithTable: (NSString *) table ofType: (enum GPKGSTableType) tableType;

-(void) add:(MCTable *) table;

-(void) remove:(MCTable *) table;

-(BOOL) isEmpty;

@end
