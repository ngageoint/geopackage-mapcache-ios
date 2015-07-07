//
//  GPKGManagerTableViewController.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGManagerTableView.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGSFeatureTable.h"
#import "GPKGSTileTable.h"
#import "GPKGSDatabase.h"
#import "GPKGTableCell.h"
#import "GPKGCell.h"

@interface GPKGManagerTableView ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) NSArray *databases;
@property (nonatomic, strong) NSMutableArray *databaseTables;
@property (nonatomic, strong) NSMutableArray *tableCells;

@end

@implementation GPKGManagerTableView

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
        cell = [tableView dequeueReusableCellWithIdentifier:@"GeoPackageCell" forIndexPath:indexPath];
        GPKGCell * dbCell = (GPKGCell *) cell;
        GPKGSDatabase * database = (GPKGSDatabase *) cellObject;
        [dbCell.database setText:database.name];
        NSString *expandImage = database.expanded ? @"Up" : @"Down";
        [dbCell.expandImage setImage:[UIImage imageNamed:expandImage]];
    }else{
        cell = [tableView dequeueReusableCellWithIdentifier:@"GeoPackageTableCell" forIndexPath:indexPath];
        GPKGTableCell * tableCell = (GPKGTableCell *) cell;
        GPKGSTable * table = (GPKGSTable *) cellObject;
        NSString * typeImage = nil;
        if([cellObject isKindOfClass:[GPKGSFeatureTable class]]){
            GPKGSFeatureTable * featureTable = (GPKGSFeatureTable *) cellObject;
            typeImage = @"Geometry";
            if(featureTable.geometryType != WKB_NONE){
                switch(featureTable.geometryType){
                    case WKB_POINT:
                    case WKB_MULTIPOINT:
                        typeImage = @"Point";
                        break;
                    case WKB_LINESTRING:
                    case WKB_MULTILINESTRING:
                    case WKB_CURVE:
                    case WKB_COMPOUNDCURVE:
                    case WKB_CIRCULARSTRING:
                    case WKB_MULTICURVE:
                        typeImage = @"Linestring";
                        break;
                    case WKB_POLYGON:
                    case WKB_SURFACE:
                    case WKB_CURVEPOLYGON:
                    case WKB_TRIANGLE:
                    case WKB_POLYHEDRALSURFACE:
                    case WKB_TIN:
                    case WKB_MULTIPOLYGON:
                    case WKB_MULTISURFACE:
                        typeImage = @"Polygon";
                        break;
                    case WKB_GEOMETRY:
                    case WKB_GEOMETRYCOLLECTION:
                    case WKB_NONE:
                        typeImage = @"Geometry";
                        break;
                }
            }
        }else if([cellObject isKindOfClass:[GPKGSTileTable class]]){
            typeImage = @"Tiles";
        } else{
            typeImage = @"Paint";
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

//- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
//    NSString * database =  [[self.manager databases] objectAtIndex:section];
//    return database;
//}

//-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
//{
//    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"GeoPackageCell"];
    
//    NSString * database = [self tableView:tableView titleForHeaderInSection:section];
//    [[cell textLabel] setText:database];
    
//    return cell;
//}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
