//
//  GPKGSDatabase.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSDatabase.h"

@interface GPKGSDatabase ()

@property (nonatomic, strong) NSMutableOrderedSet *featuresSet;
@property (nonatomic, strong) NSMutableOrderedSet *featureNamesSet;
@property (nonatomic, strong) NSMutableOrderedSet *tilesSet;
@property (nonatomic, strong) NSMutableOrderedSet *tileNamesSet;
@property (nonatomic, strong) NSMutableOrderedSet *featureOverlaysSet;
@property (nonatomic, strong) NSMutableOrderedSet *featureOverlayNamesSet;

@end

@implementation GPKGSDatabase

-(instancetype) initWithName: (NSString *) name andExpanded: (BOOL) expanded{
    self = [super init];
    if(self != nil){
        self.name = name;
        self.expanded = expanded;
        self.featuresSet = [[NSMutableOrderedSet alloc] init];
        self.featureNamesSet = [[NSMutableOrderedSet alloc] init];
        self.tilesSet = [[NSMutableOrderedSet alloc] init];
        self.tileNamesSet = [[NSMutableOrderedSet alloc] init];
        self.featureOverlaysSet = [[NSMutableOrderedSet alloc] init];
        self.featureOverlayNamesSet = [[NSMutableOrderedSet alloc] init];
    }
    return self;
}

-(NSArray *) getFeatures{
    return [self.featuresSet array];
}

-(NSInteger) getFeatureCount{
    return [self.featuresSet count];
}

-(NSArray *) getFeatureOverlays{
    return [self.featureOverlaysSet array];
}

-(NSInteger) getFeatureOverlayCount{
    return [self.featureOverlaysSet count];
}

-(NSInteger) getActiveFeatureOverlayCount{
    int count = 0;
    for(GPKGSTable * table in self.featureOverlaysSet){
        if(table.active){
            count++;
        }
    }
    return count;
}

-(NSArray *) getTiles{
    return [self.tilesSet array];
}

-(NSInteger) getTileCount{
    return [self.tilesSet count];
}

- (NSInteger) activeTileTableCount {
    NSInteger activeCount = 0;
    if ([self.tilesSet count] > 0) {
        for (GPKGSTable *table in self.tilesSet.array) {
            if (table.active) {
                activeCount++;
            }
        }
    }
    
    return activeCount;
}

- (NSInteger) activeFeatureTableCount {
    NSInteger activeCount = 0;
    if ([self.featuresSet count] > 0) {
        for (GPKGSTable *table in self.tilesSet.array) {
            if (table.active) {
                activeCount++;
            }
        }
    }
    
    return activeCount;
}

-(NSArray *) getTables{
    NSMutableArray * tables = [[NSMutableArray alloc] init];
    [tables addObjectsFromArray:[self getFeatures]];
    [tables addObjectsFromArray:[self getTiles]];
    [tables addObjectsFromArray:[self getFeatureOverlays]];
    return tables;
}

-(NSInteger) getTableCount{
    return [self getFeatureCount] + [self getTileCount] + [self getFeatureOverlayCount];
}

-(NSInteger) getActiveTableCount{ 
    return [self activeFeatureTableCount] + [self activeTileTableCount] + [self getActiveFeatureOverlayCount];
}

-(void) addFeature: (GPKGSTable *) table{
    [self.featuresSet addObject:table];
    [self.featureNamesSet addObject:table.name];
}

-(void) addFeatureOverlay: (GPKGSTable *) table{
    [self.featureOverlaysSet addObject:table];
    [self.featureOverlayNamesSet addObject:table.name];
}

-(void) addTile: (GPKGSTable *) table{
    [self.tilesSet addObject:table];
    [self.tileNamesSet addObject:table.name];
}

-(void) removeFeature: (GPKGSTable *) table{
    NSUInteger index = [self.featureNamesSet indexOfObject:table.name];
    if(index != NSNotFound){
        [self.featuresSet removeObjectAtIndex:index];
        [self.featureNamesSet removeObjectAtIndex:index];
    }
}

-(void) removeFeatureOverlay: (GPKGSTable *) table{
    NSUInteger index = [self.featureOverlayNamesSet indexOfObject:table.name];
    if(index != NSNotFound){
        [self.featureOverlaysSet removeObjectAtIndex:index];
        [self.featureOverlayNamesSet removeObjectAtIndex:index];
    }
}

-(void) removeTile: (GPKGSTable *) table{
    NSUInteger index = [self.tileNamesSet indexOfObject:table.name];
    if(index != NSNotFound){
        [self.tilesSet removeObjectAtIndex:index];
        [self.tileNamesSet removeObjectAtIndex:index];
    }
}

-(BOOL) exists: (GPKGSTable *) table{
    return [self existsWithTable:table.name ofType:[table getType]];
}

-(BOOL) existsWithTable: (NSString *) table ofType: (enum GPKGSTableType) tableType{
    
    BOOL exists = false;
    
    switch(tableType){
        case GPKGS_TT_FEATURE:
            exists = [self.featureNamesSet indexOfObject:table] != NSNotFound;
            break;
        case GPKGS_TT_TILE:
            exists = [self.tileNamesSet indexOfObject:table] != NSNotFound;
            break;
        case GPKGS_TT_FEATURE_OVERLAY:
            exists = [self.featureOverlayNamesSet indexOfObject:table] != NSNotFound;
            break;
        default:
            [NSException raise:@"Unsupported" format:@"Unsupported table type: %u", tableType];
    }
    
    return exists;
}

-(void) add:(GPKGSTable *) table{
    switch([table getType]){
        case GPKGS_TT_FEATURE:
            [self addFeature:table];
            break;
        case GPKGS_TT_TILE:
            [self addTile:table];
            break;
        case GPKGS_TT_FEATURE_OVERLAY:
            [self addFeatureOverlay:table];
            break;
        default:
            [NSException raise:@"Unsupported" format:@"Unsupported table type: %u", [table getType]];
    }
}

-(void) remove:(GPKGSTable *) table{
    switch([table getType]){
        case GPKGS_TT_FEATURE:
            [self removeFeature:table];
            break;
        case GPKGS_TT_TILE:
            [self removeTile:table];
            break;
        case GPKGS_TT_FEATURE_OVERLAY:
            [self removeFeatureOverlay:table];
            break;
        default:
            [NSException raise:@"Unsupported" format:@"Unsupported table type: %u", [table getType]];
    }
}

-(BOOL) isEmpty{
    return [self getTableCount] == 0;
}

@end
