//
//  GPKGSManagerViewController.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSManagerViewController.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGSFeatureTable.h"
#import "GPKGSTileTable.h"
#import "GPKGSDatabase.h"
#import "GPKGSTableCell.h"
#import "GPKGSDatabaseCell.h"
#import "GPKGSConstants.h"

@interface GPKGSManagerViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) NSArray *databases;
@property (nonatomic, strong) NSMutableArray *databaseTables;
@property (nonatomic, strong) NSMutableArray *tableCells;

@end

@implementation GPKGSManagerViewController

-(void)viewDidLoad{
    [super viewDidLoad];
    self.manager = [GPKGGeoPackageFactory getManager];
    [self update];
}

-(void) update{
    self.databases = [self.manager databases];
    self.databaseTables = [[NSMutableArray alloc] init];
    self.tableCells = [[NSMutableArray alloc] init];
    for(NSString * database in self.databases){
        GPKGGeoPackage * geoPackage = [self.manager open:database];
        @try {
            GPKGSDatabase * theDatabase = [[GPKGSDatabase alloc] init];
            theDatabase.name = database;
            [self.tableCells addObject:theDatabase];
            NSMutableArray * tables = [[NSMutableArray alloc] init];
            
            NSMutableArray * featureTables = [[NSMutableArray alloc] init];
            GPKGContentsDao * contentsDao = [geoPackage getContentsDao];
            for(NSString * tableName in [geoPackage getFeatureTables]){
                GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:tableName];
                int count = [featureDao count];
                
                GPKGContents * contents = (GPKGContents *)[contentsDao queryForIdObject:tableName];
                GPKGGeometryColumns * geometryColumns = [contentsDao getGeometryColumns:contents];
                enum WKBGeometryType geometryType = [WKBGeometryTypes fromName:geometryColumns.geometryTypeName];
                
                GPKGSFeatureTable * table = [[GPKGSFeatureTable alloc] init];
                [table setDatabase:database];
                [table setName:tableName];
                [table setGeometryType:geometryType];
                [table setCount:count];
                //[table setActive:false];
                
                [tables addObject:table];
                [featureTables addObject:table];
                //[self.tableCells addObject:table];
            }
            theDatabase.features = featureTables;
            
            NSMutableArray * tileTables = [[NSMutableArray alloc] init];
            for(NSString * tableName in [geoPackage getTileTables]){
                GPKGTileDao * tileDao = [geoPackage getTileDaoWithTableName: tableName];
                int count = [tileDao count];
                
                GPKGSTileTable * table = [[GPKGSTileTable alloc] init];
                [table setDatabase:database];
                [table setName:tableName];
                [table setCount:count];
                //[table setActive:false];
                
                [tables addObject:table];
                [tileTables addObject:table];
                //[self.tableCells addObject:table];
            }
            theDatabase.tiles = tileTables;
            
            // TODO overlays
            
            [self.databaseTables addObject:tables];
        }
        @finally {
            [geoPackage close];
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.tableCells count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *cell = nil;
    
    NSObject * cellObject = [self.tableCells objectAtIndex:indexPath.row];
    if([cellObject isKindOfClass:[GPKGSDatabase class]]){
        cell = [tableView dequeueReusableCellWithIdentifier:GPKGS_CELL_DATABASE forIndexPath:indexPath];
        GPKGSDatabaseCell * dbCell = (GPKGSDatabaseCell *) cell;
        GPKGSDatabase * database = (GPKGSDatabase *) cellObject;
        [dbCell.database setText:database.name];
        NSString *expandImage = database.expanded ? GPKGS_ICON_UP : GPKGS_ICON_DOWN;
        [dbCell.expandImage setImage:[UIImage imageNamed:expandImage]];
    }else{
        cell = [tableView dequeueReusableCellWithIdentifier:GPKGS_CELL_TABLE forIndexPath:indexPath];
        GPKGSTableCell * tableCell = (GPKGSTableCell *) cell;
        GPKGSTable * table = (GPKGSTable *) cellObject;
        NSString * typeImage = nil;
        if([cellObject isKindOfClass:[GPKGSFeatureTable class]]){
            GPKGSFeatureTable * featureTable = (GPKGSFeatureTable *) cellObject;
            typeImage = GPKGS_ICON_GEOMETRY;
            if(featureTable.geometryType != WKB_NONE){
                switch(featureTable.geometryType){
                    case WKB_POINT:
                    case WKB_MULTIPOINT:
                        typeImage = GPKGS_ICON_POINT;
                        break;
                    case WKB_LINESTRING:
                    case WKB_MULTILINESTRING:
                    case WKB_CURVE:
                    case WKB_COMPOUNDCURVE:
                    case WKB_CIRCULARSTRING:
                    case WKB_MULTICURVE:
                        typeImage = GPKGS_ICON_LINESTRING;
                        break;
                    case WKB_POLYGON:
                    case WKB_SURFACE:
                    case WKB_CURVEPOLYGON:
                    case WKB_TRIANGLE:
                    case WKB_POLYHEDRALSURFACE:
                    case WKB_TIN:
                    case WKB_MULTIPOLYGON:
                    case WKB_MULTISURFACE:
                        typeImage = GPKGS_ICON_POLYGON;
                        break;
                    case WKB_GEOMETRY:
                    case WKB_GEOMETRYCOLLECTION:
                    case WKB_NONE:
                        typeImage = GPKGS_ICON_GEOMETRY;
                        break;
                }
            }
        }else if([cellObject isKindOfClass:[GPKGSTileTable class]]){
            typeImage = GPKGS_ICON_TILES;
        } else{
            typeImage = GPKGS_ICON_PAINT;
        }
        tableCell.active.on = table.active;
        if(typeImage != nil){
            [tableCell.tableType setImage:[UIImage imageNamed:typeImage]];
        }
        [tableCell.tableName setText:table.name];
        [tableCell.count setText:[NSString stringWithFormat:@"(%d)", table.count]];
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

    return cell;
}

-(void) tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSObject * cellObject = [self.tableCells objectAtIndex:indexPath.row];
    if([cellObject isKindOfClass:[GPKGSDatabase class]]){
        GPKGSDatabase * database = (GPKGSDatabase *) cellObject;
        [self expandOrCollapseDatabase:database atIndexPath:indexPath];
    }
}

-(void) expandOrCollapseDatabase: (GPKGSDatabase *) database atIndexPath:(NSIndexPath *)indexPath{
    
    if(database.expanded){
        for(NSInteger i = indexPath.row + 1; i < self.tableCells.count;){
            NSObject * cellObject = [self.tableCells objectAtIndex:i];
            if([cellObject isKindOfClass:[GPKGSDatabase class]]){
                break;
            }else{
                [self.tableCells removeObjectAtIndex:i];
            }
        }
    }else{
        NSInteger i = [self.tableCells count];
        [self.tableCells insertObjects:database.features atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(i, [database.features count])]];
        i = i + [database.features count];
        [self.tableCells insertObjects:database.tiles atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(i, [database.tiles count])]];
        i = i + [database.tiles count];
        [self.tableCells insertObjects:database.featureOverlays atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(i, [database.featureOverlays count])]];
    }
    database.expanded = !database.expanded;
    
    [self.tableView reloadData];
}

@end
