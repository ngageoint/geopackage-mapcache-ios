//
//  GPKGSDatabase.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSDatabase.h"

@interface GPKGSDatabase ()

@property (nonatomic, strong) NSMutableDictionary *featuresDictionary;
@property (nonatomic, strong) NSMutableDictionary *tilesDictionary;
@property (nonatomic, strong) NSMutableDictionary *featureOverlaysDictionary;
@property (nonatomic, strong) NSMutableArray *featuresArray;
@property (nonatomic, strong) NSMutableArray *tilesArray;
@property (nonatomic, strong) NSMutableArray *featureOverlaysArray;

@end

@implementation GPKGSDatabase

-(instancetype) initWithName: (NSString *) name andExpanded: (BOOL) expanded{
    self = [super init];
    if(self != nil){
        self.name = name;
        self.expanded = expanded;
        self.featuresDictionary = [[NSMutableDictionary alloc] init];
        self.tilesDictionary = [[NSMutableDictionary alloc] init];
        self.featureOverlaysDictionary = [[NSMutableDictionary alloc] init];
        self.featuresArray = [[NSMutableArray alloc] init];
        self.tilesArray = [[NSMutableArray alloc] init];
        self.featureOverlaysArray = [[NSMutableArray alloc] init];
    }
    return self;
}

-(NSArray *) getFeatures{
    return self.featuresArray;
}

-(NSInteger) getFeatureCount{
    return [self.featuresArray count];
}

-(NSArray *) getFeatureOverlays{
    return self.featureOverlaysArray;
}

-(NSInteger) getFeatureOverlayCount{
    return [self.featureOverlaysArray count];
}

-(NSArray *) getTiles{
    return self.tilesArray;
}

-(NSInteger) getTileCount{
    return [self.tilesArray count];
}

-(NSArray *) getTables{
    NSMutableArray * tables = [[NSMutableArray alloc] init];
    [tables addObjectsFromArray:self.featuresArray];
    [tables addObjectsFromArray:self.tilesArray];
    [tables addObjectsFromArray:self.featureOverlaysArray];
    return tables;
}

-(NSInteger) getTableCount{
    return [self getFeatureCount] + [self getTileCount] + [self getFeatureOverlayCount];
}

-(void) addFeature: (GPKGSTable *) table{
    NSInteger index = [self.featuresArray count];
    [self.featuresArray addObject:table];
    [self.featuresDictionary setObject:[NSNumber numberWithInteger:index] forKey:table.name];
}

-(void) addFeatureOverlay: (GPKGSTable *) table{
    NSInteger index = [self.featureOverlaysArray count];
    [self.featureOverlaysArray addObject:table];
    [self.featureOverlaysDictionary setObject:[NSNumber numberWithInteger:index] forKey:table.name];
}

-(void) addTile: (GPKGSTable *) table{
    NSInteger index = [self.tilesArray count];
    [self.tilesArray addObject:table];
    [self.tilesDictionary setObject:[NSNumber numberWithInteger:index] forKey:table.name];
}

-(void) removeFeature: (GPKGSTable *) table{
    NSNumber * index = [self.featuresDictionary objectForKey:table.name];
    if(index != nil){
        [self.featuresDictionary removeObjectForKey:table.name];
        [self.featuresArray removeObjectAtIndex:[index integerValue]];
    }
}

-(void) removeFeatureOverlay: (GPKGSTable *) table{
    NSNumber * index = [self.featureOverlaysDictionary objectForKey:table.name];
    if(index != nil){
        [self.featureOverlaysDictionary removeObjectForKey:table.name];
        [self.featureOverlaysArray removeObjectAtIndex:[index integerValue]];
    }
}

-(void) removeTile: (GPKGSTable *) table{
    NSNumber * index = [self.tilesDictionary objectForKey:table.name];
    if(index != nil){
        [self.tilesDictionary removeObjectForKey:table.name];
        [self.tilesArray removeObjectAtIndex:[index integerValue]];
    }
}

-(BOOL) exists: (GPKGSTable *) table{
    
    BOOL exists = false;
    
    switch([table getType]){
        case GPKGS_TT_FEATURE:
            exists = [self.featuresDictionary objectForKey:table.name] != nil;
            break;
        case GPKGS_TT_TILE:
            exists = [self.tilesDictionary objectForKey:table.name] != nil;
            break;
        case GPKGS_TT_FEATURE_OVERLAY:
            exists = [self.featureOverlaysDictionary objectForKey:table.name] != nil;
            break;
        default:
            [NSException raise:@"Unsupported" format:@"Unsupported table type: %u", [table getType]];
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
