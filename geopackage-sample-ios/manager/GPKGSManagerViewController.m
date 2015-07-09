//
//  GPKGSManagerViewController.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSManagerViewController.h"
#import <objc/runtime.h>
#import "GPKGGeoPackageFactory.h"
#import "GPKGSFeatureTable.h"
#import "GPKGSTileTable.h"
#import "GPKGSDatabase.h"
#import "GPKGSTableCell.h"
#import "GPKGSDatabaseCell.h"
#import "GPKGSConstants.h"
#import "GPKGSActiveTableSwitch.h"
#import "GPKGSProperties.h"
#import "GPKGSUtils.h"

NSString * const GPKGS_MANAGER_SEG_DOWNLOAD_FILE = @"downloadFile";

const char ConstantKey;

@interface GPKGSManagerViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) NSArray *databases;
@property (nonatomic, strong) NSMutableArray *databaseTables;
@property (nonatomic, strong) NSMutableArray *tableCells;

@end

@implementation GPKGSManagerViewController

#define TAG_DATABASE_OPTIONS 1
#define TAG_TABLE_OPTIONS 2
#define TAG_DATABASE_DELETE 3
#define TAG_DATABASE_CREATE 4
#define TAG_DATABASE_RENAME 5
#define TAG_DATABASE_COPY 6

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

-(void) updateAndReloadData{
    [self update];
    [self.tableView reloadData];
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
        NSString *expandImage = database.expanded ? [GPKGSProperties getValueOfProperty:GPKGS_PROP_ICON_UP] : [GPKGSProperties getValueOfProperty:GPKGS_PROP_ICON_DOWN];
        [dbCell.expandImage setImage:[UIImage imageNamed:expandImage]];
        [dbCell.optionsButton setDatabase:database];
    }else{
        cell = [tableView dequeueReusableCellWithIdentifier:GPKGS_CELL_TABLE forIndexPath:indexPath];
        GPKGSTableCell * tableCell = (GPKGSTableCell *) cell;
        GPKGSTable * table = (GPKGSTable *) cellObject;
        NSString * typeImage = nil;
        if([cellObject isKindOfClass:[GPKGSFeatureTable class]]){
            GPKGSFeatureTable * featureTable = (GPKGSFeatureTable *) cellObject;
            typeImage = [GPKGSProperties getValueOfProperty:GPKGS_PROP_ICON_GEOMETRY];
            if(featureTable.geometryType != WKB_NONE){
                switch(featureTable.geometryType){
                    case WKB_POINT:
                    case WKB_MULTIPOINT:
                        typeImage = [GPKGSProperties getValueOfProperty:GPKGS_PROP_ICON_POINT];
                        break;
                    case WKB_LINESTRING:
                    case WKB_MULTILINESTRING:
                    case WKB_CURVE:
                    case WKB_COMPOUNDCURVE:
                    case WKB_CIRCULARSTRING:
                    case WKB_MULTICURVE:
                        typeImage = [GPKGSProperties getValueOfProperty:GPKGS_PROP_ICON_LINESTRING];
                        break;
                    case WKB_POLYGON:
                    case WKB_SURFACE:
                    case WKB_CURVEPOLYGON:
                    case WKB_TRIANGLE:
                    case WKB_POLYHEDRALSURFACE:
                    case WKB_TIN:
                    case WKB_MULTIPOLYGON:
                    case WKB_MULTISURFACE:
                        typeImage = [GPKGSProperties getValueOfProperty:GPKGS_PROP_ICON_POLYGON];
                        break;
                    case WKB_GEOMETRY:
                    case WKB_GEOMETRYCOLLECTION:
                    case WKB_NONE:
                        typeImage = [GPKGSProperties getValueOfProperty:GPKGS_PROP_ICON_GEOMETRY];
                        break;
                }
            }
        }else if([cellObject isKindOfClass:[GPKGSTileTable class]]){
            typeImage = [GPKGSProperties getValueOfProperty:GPKGS_PROP_ICON_TILES];
        } else{
            typeImage = [GPKGSProperties getValueOfProperty:GPKGS_PROP_ICON_PAINT];
        }
        tableCell.active.on = table.active;
        if(typeImage != nil){
            [tableCell.tableType setImage:[UIImage imageNamed:typeImage]];
        }
        [tableCell.tableName setText:table.name];
        [tableCell.count setText:[NSString stringWithFormat:@"(%d)", table.count]];
        [tableCell.active setTable:table];
        [tableCell.optionsButton setTable:table];
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
        NSInteger i = indexPath.row + 1;
        [self.tableCells insertObjects:database.features atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(i, [database.features count])]];
        i = i + [database.features count];
        [self.tableCells insertObjects:database.tiles atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(i, [database.tiles count])]];
        i = i + [database.tiles count];
        [self.tableCells insertObjects:database.featureOverlays atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(i, [database.featureOverlays count])]];
    }
    database.expanded = !database.expanded;
    
    [self.tableView reloadData];
}

- (IBAction)tableActiveChanged:(GPKGSActiveTableSwitch *)sender {
    GPKGSTable * table = sender.table;
    table.active = sender.on;
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch(alertView.tag){
        case TAG_DATABASE_OPTIONS:
            [self handleDatabaseOptionsWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
        case TAG_TABLE_OPTIONS:
            [self handleTableOptionsWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
        case TAG_DATABASE_DELETE:
            [self handleDeleteDatabaseWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
        case TAG_DATABASE_CREATE:
            [self handleCreateWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
        case TAG_DATABASE_RENAME:
            [self handleRenameDatabaseWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
        case TAG_DATABASE_COPY:
            [self handleCopyDatabaseWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
    }
}

// TODO delete when no longer used
-(void) todoAlert: (NSString *) name{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:[NSString stringWithFormat:@"TODO: %@", name]
                          message:nil
                          delegate:self
                          cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                          otherButtonTitles:
                          nil];
    [alert show];
}

- (IBAction)databaseOptions:(GPKGSDatabaseOptionsButton *)sender {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:sender.database.name
                          message:nil
                          delegate:self
                          cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                          otherButtonTitles:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_VIEW_LABEL],
                          [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_DELETE_LABEL],
                          [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_RENAME_LABEL],
                          [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_COPY_LABEL],
                          [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_EXPORT_LABEL],
                          [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_SHARE_LABEL],
                          [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_CREATE_FEATURES_LABEL],
                          [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_CREATE_TILES_LABEL],
                          nil];
    
    alert.tag = TAG_DATABASE_OPTIONS;
    
    objc_setAssociatedObject(alert, &ConstantKey, sender.database, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [alert show];
}

- (void) handleDatabaseOptionsWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex > 0){
        
        GPKGSDatabase *database = objc_getAssociatedObject(alertView, &ConstantKey);
        switch (buttonIndex) {
            case 1:
                [self todoAlert: [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_VIEW_LABEL]];
                break;
            case 2:
                [self deleteDatabaseOption:database.name];
                break;
            case 3:
                [self renameDatabaseOption:database.name];
                break;
            case 4:
                [self copyDatabaseOption:database.name];
                break;
            case 5:
                [self todoAlert: [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_EXPORT_LABEL]];
                break;
            case 6:
                [self todoAlert: [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_SHARE_LABEL]];
                break;
            case 7:
                [self todoAlert: [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_CREATE_FEATURES_LABEL]];
                break;
            case 8:
                [self todoAlert: [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_CREATE_TILES_LABEL]];
                break;
            default:
                break;
        }
    }
}

- (IBAction)tableOptions:(GPKGSTableOptionsButton *)sender {
    
    NSMutableArray * options = [[NSMutableArray alloc] init];
    [options addObject:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_VIEW_LABEL]];
    [options addObject:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_EDIT_LABEL]];
    [options addObject:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_DELETE_LABEL]];
    
    switch([sender.table getType]){
        case GPKGS_TT_FEATURE:
            [options addObject:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_LABEL]];
            [options addObject:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_CREATE_FEATURE_TILES_LABEL]];
            [options addObject:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_ADD_FEATURE_OVERLAY_LABEL]];
            break;
        case GPKGS_TT_TILE:
            [options addObject:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_TILES_LOAD_LABEL]];
            break;
        case GPKGS_TT_FEATURE_OVERLAY:
            break;
        default:
            [NSException raise:@"Unsupported" format:@"Unsupported table type: %@", [GPKGSTableTypes name:sender.table.getType]];
    }
    
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:sender.table.name
                          message:nil
                          delegate:self
                          cancelButtonTitle:nil
                          otherButtonTitles:nil];
                          
    for (NSString *option in options) {
        [alert addButtonWithTitle:option];
    }
    alert.cancelButtonIndex = [alert addButtonWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]];
                          
    alert.tag = TAG_TABLE_OPTIONS;
    
    objc_setAssociatedObject(alert, &ConstantKey, sender.table, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [alert show];
}

- (void) handleTableOptionsWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex >= 0){
        
        GPKGSTable *table = objc_getAssociatedObject(alertView, &ConstantKey);
        switch(buttonIndex){
            case 0:
                switch([table getType]){
                    case GPKGS_TT_FEATURE:
                    case GPKGS_TT_TILE:
                    case GPKGS_TT_FEATURE_OVERLAY:
                        [self todoAlert: [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_VIEW_LABEL]];
                        break;
                }
                break;
            case 1:
                switch([table getType]){
                    case GPKGS_TT_FEATURE:
                    case GPKGS_TT_TILE:
                        [self todoAlert: [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_EDIT_LABEL]];
                        break;
                    case GPKGS_TT_FEATURE_OVERLAY:
                        [self todoAlert: [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_EDIT_LABEL]];
                        break;
                }
                break;
            case 2:
                switch([table getType]){
                    case GPKGS_TT_FEATURE:
                    case GPKGS_TT_TILE:
                        [self todoAlert: [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_DELETE_LABEL]];
                        break;
                    case GPKGS_TT_FEATURE_OVERLAY:
                        [self todoAlert: [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_DELETE_LABEL]];
                        break;
                }
                break;
            case 3:
                switch([table getType]){
                    case GPKGS_TT_FEATURE:
                        [self todoAlert: [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_LABEL]];
                        break;
                    case GPKGS_TT_TILE:
                        [self todoAlert: [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_TILES_LOAD_LABEL]];
                        break;
                    default:
                        break;
                }
                break;
            case 4:
                switch([table getType]){
                    case GPKGS_TT_FEATURE:
                        [self todoAlert: [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_CREATE_FEATURE_TILES_LABEL]];
                        break;
                    default:
                        break;
                }
                break;
            case 5:
                switch([table getType]){
                    case GPKGS_TT_FEATURE:
                        [self todoAlert: [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_ADD_FEATURE_OVERLAY_LABEL]];
                        break;
                    default:
                        break;
                }
                break;
            default:
                break;
        }
        
    }
}

-(void) deleteDatabaseOption: (NSString *) database{
    NSString * label = [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_DELETE_LABEL];
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:label
                          message:[NSString stringWithFormat:@"%@ %@?", label, database]
                          delegate:self
                          cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                          otherButtonTitles:label,
                          nil];
    alert.tag = TAG_DATABASE_DELETE;
    objc_setAssociatedObject(alert, &ConstantKey, database, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [alert show];
}

- (void) handleDeleteDatabaseWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex > 0){
        NSString *database = objc_getAssociatedObject(alertView, &ConstantKey);
        [self.manager delete:database];
        //TODO remove from active?
        [self updateAndReloadData];
    }
}

-(void) renameDatabaseOption: (NSString *) database{
    UIAlertView * alert = [[UIAlertView alloc]
                           initWithTitle:[NSString stringWithFormat:@"%@ '%@'", [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_RENAME_LABEL], database]
                           message:nil
                           delegate:self
                           cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                           otherButtonTitles:[GPKGSProperties getValueOfProperty:GPKGS_PROP_OK_LABEL],
                           nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = TAG_DATABASE_RENAME;
    objc_setAssociatedObject(alert, &ConstantKey, database, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [alert show];
}

- (void) handleRenameDatabaseWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex > 0){
        NSString * newName = [[alertView textFieldAtIndex:0] text];
        NSString *database = objc_getAssociatedObject(alertView, &ConstantKey);
        if(newName != nil && [newName length] > 0 && ![newName isEqualToString:database]){
            @try {
                if([self.manager rename:database to:newName]){
                    //TODO rename active?
                    [self updateAndReloadData];
                }else{
                    [GPKGSUtils showMessageWithDelegate:self
                                               andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_RENAME_LABEL]
                                             andMessage:[NSString stringWithFormat:@"Rename from %@ to %@ was not successful", database, newName]];
                }
            }
            @catch (NSException *exception) {
                [GPKGSUtils showMessageWithDelegate:self
                                           andTitle:[NSString stringWithFormat:@"Rename %@ to %@", database, newName]
                                         andMessage:[NSString stringWithFormat:@"%@", [exception description]]];
            }
        }
    }
}

-(void) copyDatabaseOption: (NSString *) database{
    UIAlertView * alert = [[UIAlertView alloc]
                           initWithTitle:[NSString stringWithFormat:@"%@ '%@'", [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_COPY_LABEL], database]
                           message:nil
                           delegate:self
                           cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                           otherButtonTitles:[GPKGSProperties getValueOfProperty:GPKGS_PROP_OK_LABEL],
                           nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    [[alert textFieldAtIndex:0] setText:[NSString stringWithFormat:@"%@%@", database, [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_COPY_SUFFIX]]];
    alert.tag = TAG_DATABASE_COPY;
    objc_setAssociatedObject(alert, &ConstantKey, database, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [alert show];
}

- (void) handleCopyDatabaseWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex > 0){
        NSString * newName = [[alertView textFieldAtIndex:0] text];
        NSString *database = objc_getAssociatedObject(alertView, &ConstantKey);
        if(newName != nil && [newName length] > 0 && ![newName isEqualToString:database]){
            @try {
                if([self.manager copy:database to:newName]){
                    [self updateAndReloadData];
                }else{
                    [GPKGSUtils showMessageWithDelegate:self
                                               andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_COPY_LABEL]
                                             andMessage:[NSString stringWithFormat:@"Copy from %@ to %@ was not successful", database, newName]];
                }
            }
            @catch (NSException *exception) {
                [GPKGSUtils showMessageWithDelegate:self
                                           andTitle:[NSString stringWithFormat:@"Copy %@ to %@", database, newName]
                                         andMessage:[NSString stringWithFormat:@"%@", [exception description]]];
            }
        }
    }
}

- (IBAction)downloadFile:(id)sender {
    [self performSegueWithIdentifier:GPKGS_MANAGER_SEG_DOWNLOAD_FILE sender:self];
}

- (IBAction)importFile:(id)sender {
    //TODO
    [self todoAlert: @"Import File"];
}

- (IBAction)create:(id)sender {
    UIAlertView * alert = [[UIAlertView alloc]
                           initWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_CREATE_LABEL]
                           message:nil
                           delegate:self
                           cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                           otherButtonTitles:[GPKGSProperties getValueOfProperty:GPKGS_PROP_OK_LABEL],
                           nil];
    alert.alertViewStyle = UIAlertViewStylePlainTextInput;
    alert.tag = TAG_DATABASE_CREATE;
    [alert show];
}

- (void) handleCreateWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex > 0){
        NSString * createName = [[alertView textFieldAtIndex:0] text];
        if(createName != nil && [createName length] > 0){
            @try {
                if([self.manager create:createName]){
                    [self updateAndReloadData];
                }else{
                    [GPKGSUtils showMessageWithDelegate:self
                                               andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_CREATE_LABEL]
                                             andMessage:[NSString stringWithFormat:@"Failed to create GeoPackage: %@", createName]];
                }
            }
            @catch (NSException *exception) {
                [GPKGSUtils showMessageWithDelegate:self
                                           andTitle:[NSString stringWithFormat:@"%@ %@", [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_CREATE_LABEL], createName]
                                         andMessage:[NSString stringWithFormat:@"%@", [exception description]]];
            }
        }
    }
}

- (IBAction)clearActive:(id)sender {
    // TODO
    [self todoAlert: @"Clear Active"];
}

- (void)downloadFileViewController:(GPKGSDownloadFileViewController *)controller downloadedFile:(BOOL)downloaded withError: (NSString *) error{
    if(downloaded){
        [self updateAndReloadData];
    }
    if(error != nil){
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_IMPORT_URL_ERROR]
                                 andMessage:[NSString stringWithFormat:@"Error downloading '%@' at:\n%@\n\nError: %@", controller.nameTextField.text, controller.urlTextField.text, error]];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([segue.identifier isEqualToString:GPKGS_MANAGER_SEG_DOWNLOAD_FILE])
    {
        GPKGSDownloadFileViewController *downloadFileViewController = segue.destinationViewController;
        downloadFileViewController.delegate = self;
    }
    
}

@end
