//
//  GPKGSManagerViewController.m
//  mapcache-ios
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
#import "GPKGSDisplayTextViewController.h"
#import "GPKGSFeatureOverlayTable.h"
#import "GPKGSDatabases.h"
#import "GPKGSIndexerTask.h"
#import "GPKGSCreateFeaturesViewController.h"
#import "GPKGSManagerCreateTilesViewController.h"
#import "GPKGSManagerLoadTilesViewController.h"
#import "GPKGSEditFeaturesViewController.h"
#import "GPKGSEditTilesViewController.h"
#import "GPKGSCreateFeatureTilesViewController.h"
#import "GPKGSAddTileOverlayViewController.h"
#import "GPKGSManagerEditTileOverlayViewController.h"
#import "GPKGFeatureIndexManager.h"
#import "GPKGSTableIndex.h"
#import "GPKGSLinkedTablesViewController.h"

NSString * const GPKGS_MANAGER_SEG_DOWNLOAD_FILE = @"downloadFile";
NSString * const GPKGS_MANAGER_SEG_DISPLAY_TEXT = @"displayText";
NSString * const GPKGS_MANAGER_SEG_CREATE_FEATURES = @"createFeatures";
NSString * const GPKGS_MANAGER_SEG_CREATE_TILES = @"createTiles";
NSString * const GPKGS_EXPANDED_PREFERENCE = @"expanded";
NSString * const GPKGS_MANAGER_SEG_LOAD_TILES = @"loadTiles";
NSString * const GPKGS_MANAGER_SEG_EDIT_FEATURES = @"editFeatures";
NSString * const GPKGS_MANAGER_SEG_EDIT_TILES = @"editTiles";
NSString * const GPKGS_MANAGER_SEG_CREATE_FEATURE_TILES = @"createFeatureTiles";
NSString * const GPKGS_MANAGER_SEG_ADD_TILE_OVERLAY = @"addTileOverlay";
NSString * const GPKGS_MANAGER_SEG_EDIT_TILE_OVERLAY = @"editTileOverlay";
NSString * const GPKGS_MANAGER_SEG_LINKED_TABLES = @"linkedTables";

const char ConstantKey;

@interface GPKGSManagerViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) NSMutableDictionary *databases;
@property (nonatomic, strong) NSMutableArray *tableCells;
@property (nonatomic, strong) GPKGSDatabases *active;
@property (nonatomic, strong) NSUserDefaults * settings;
@property (nonatomic) BOOL retainModifiedForMap;
@property (nonatomic, strong) UIDocumentInteractionController *shareDocumentController;
@property (strong, nonatomic) NSMutableArray *childCoordinators;

@end

@implementation GPKGSManagerViewController

#define TAG_DATABASE_OPTIONS 1
#define TAG_TABLE_OPTIONS 2
#define TAG_DATABASE_DELETE 3
#define TAG_DATABASE_CREATE 4
#define TAG_DATABASE_RENAME 5
#define TAG_DATABASE_COPY 6
#define TAG_TABLE_DELETE 7
#define TAG_CLEAR_ACTIVE 8
#define TAG_INDEX_FEATURES 9
#define TAG_DELETE_INDEX_FEATURES 10
#define TAG_CREATE_INDEX_FEATURES 11

-(void)viewDidLoad{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateAndReloadDataNotification:)
                                                 name:GPKGS_IMPORT_GEOPACKAGE_NOTIFICATION
                                               object:nil];
    
    self.manager = [GPKGGeoPackageFactory getManager];
    self.active = [GPKGSDatabases getInstance];
    self.settings = [NSUserDefaults standardUserDefaults];
    NSArray * expandedDatabases = [self.settings stringArrayForKey:GPKGS_EXPANDED_PREFERENCE];
    self.databases = [[NSMutableDictionary alloc] init];
    for(NSString * expandedDatabase in expandedDatabases){
        [self.databases setObject:[[GPKGSDatabase alloc] initWithName:expandedDatabase andExpanded:true] forKey:expandedDatabase];
    }
    self.retainModifiedForMap = false;
    [self update];
    _childCoordinators = [[NSMutableArray alloc] init];
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [[self navigationController] setNavigationBarHidden:YES animated:NO];
    
    if(self.active.modified){
        if(self.retainModifiedForMap){
            self.retainModifiedForMap = false;
        }else{
            [self.active setModified:false];
        }
        [self updateAndReloadData];
    }
}

- (void) updateAndReloadDataNotification:(NSNotification *) notification
{
    if ([[notification name] isEqualToString:GPKGS_IMPORT_GEOPACKAGE_NOTIFICATION]){
        [self updateAndReloadData];
    }
}

-(void) update{
    NSArray * databaseNames = [self.manager databases];
    self.tableCells = [[NSMutableArray alloc] init];
    NSDictionary * previousDatabases = self.databases;
    self.databases = [[NSMutableDictionary alloc] init];
    for(NSString * database in databaseNames){
        GPKGGeoPackage * geoPackage = nil;
        @try {
            geoPackage = [self.manager open:database];
            BOOL expanded = false;
            if(previousDatabases != nil){
                GPKGSDatabase * previousDatabase = [previousDatabases objectForKey:database];
                if(previousDatabase != nil){
                    expanded = previousDatabase.expanded;
                }
            }
            
            GPKGSDatabase * theDatabase = [[GPKGSDatabase alloc] initWithName:database andExpanded:expanded];
            [self.databases setObject:theDatabase forKey:database];
            [self.tableCells addObject:theDatabase];
            NSMutableArray * tables = [[NSMutableArray alloc] init];
            
            GPKGContentsDao * contentsDao = [geoPackage getContentsDao];
            for(NSString * tableName in [geoPackage getFeatureTables]){
                GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:tableName];
                int count = [featureDao count];
                
                GPKGContents * contents = (GPKGContents *)[contentsDao queryForIdObject:tableName];
                GPKGGeometryColumns * geometryColumns = [contentsDao getGeometryColumns:contents];
                enum SFGeometryType geometryType = [SFGeometryTypes fromName:geometryColumns.geometryTypeName];
                
                GPKGSFeatureTable * table = [[GPKGSFeatureTable alloc] initWithDatabase:database andName:tableName andGeometryType:geometryType andCount:count];
                [table setActive:[self.active exists:table]];
                
                [tables addObject:table];
                [theDatabase addFeature:table];
                if(theDatabase.expanded){
                    [self.tableCells addObject:table];
                }
            }
            
            for(NSString * tableName in [geoPackage getTileTables]){
                GPKGTileDao * tileDao = [geoPackage getTileDaoWithTableName: tableName];
                int count = [tileDao count];
                
                GPKGSTileTable * table = [[GPKGSTileTable alloc] initWithDatabase:database andName:tableName andCount:count];
                [table setActive:[self.active exists:table]];
                
                [tables addObject:table];
                [theDatabase addTile:table];
                if(theDatabase.expanded){
                    [self.tableCells addObject:table];
                }
            }
            
            for(GPKGSFeatureOverlayTable * table in [self.active featureOverlays:database]){
                GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:table.featureTable];
                int count = [featureDao count];
                [table setCount:count];
                
                [tables addObject:table];
                [theDatabase addFeatureOverlay:table];
                if(theDatabase.expanded){
                    [self.tableCells addObject:table];
                }
            }
            
        }
        @finally {
            if(geoPackage == nil){
                @try {
                    [self.manager delete:database];
                }
                @catch (NSException *exception) {
                }
            }else{
                [geoPackage close];
            }
        }
    }
    [self updateClearActiveButton];
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
        if([cellObject isKindOfClass:[GPKGSFeatureOverlayTable class]]){
            typeImage = [GPKGSProperties getValueOfProperty:GPKGS_PROP_ICON_PAINT];
        }else if([cellObject isKindOfClass:[GPKGSFeatureTable class]]){
            GPKGSFeatureTable * featureTable = (GPKGSFeatureTable *) cellObject;
            typeImage = [GPKGSProperties getValueOfProperty:GPKGS_PROP_ICON_GEOMETRY];
            if(featureTable.geometryType != SF_NONE){
                switch(featureTable.geometryType){
                    case SF_POINT:
                    case SF_MULTIPOINT:
                        typeImage = [GPKGSProperties getValueOfProperty:GPKGS_PROP_ICON_POINT];
                        break;
                    case SF_LINESTRING:
                    case SF_MULTILINESTRING:
                    case SF_CURVE:
                    case SF_COMPOUNDCURVE:
                    case SF_CIRCULARSTRING:
                    case SF_MULTICURVE:
                        typeImage = [GPKGSProperties getValueOfProperty:GPKGS_PROP_ICON_LINESTRING];
                        break;
                    case SF_POLYGON:
                    case SF_SURFACE:
                    case SF_CURVEPOLYGON:
                    case SF_TRIANGLE:
                    case SF_POLYHEDRALSURFACE:
                    case SF_TIN:
                    case SF_MULTIPOLYGON:
                    case SF_MULTISURFACE:
                        typeImage = [GPKGSProperties getValueOfProperty:GPKGS_PROP_ICON_POLYGON];
                        break;
                    case SF_GEOMETRY:
                    case SF_GEOMETRYCOLLECTION:
                    case SF_NONE:
                        typeImage = [GPKGSProperties getValueOfProperty:GPKGS_PROP_ICON_GEOMETRY];
                        break;
                }
            }
        }else if([cellObject isKindOfClass:[GPKGSTileTable class]]){
            typeImage = [GPKGSProperties getValueOfProperty:GPKGS_PROP_ICON_TILES];
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
        
//        MCGeoPackageCoordinator *coordinator = [[MCGeoPackageCoordinator alloc] initWithDelegate:self andDatabase:database]; 
//        [_childCoordinators addObject:coordinator];
//        [coordinator start];
    }
}

- (void) geoPackageCoordinatorCompletionHandlerForDatabase:(NSString *)database withDelete:(BOOL)didDelete {
    
    if (didDelete) {
        [self.manager delete:database];
        [self.active removeDatabase:database andPreserveOverlays:false];
    }
    
    [self updateAndReloadData];
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
        [self.tableCells insertObjects:[database getTables] atIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(i, [database getTableCount])]];
    }
    database.expanded = !database.expanded;
    if(database.expanded){
        [self addExpandedSetting:database.name];
    }else{
        [self removeExpandedSetting:database.name];
    }
    
    [self.tableView reloadData];
}

- (IBAction)tableActiveChanged:(GPKGSActiveTableSwitch *)sender {
    GPKGSTable * table = sender.table;
    table.active = sender.on;
    
    if([table getType] == GPKGS_TT_FEATURE_OVERLAY){
        [self.active removeTable:table];
        [self.active addTable:table];
    }else{
        if(table.active){
            [self.active addTable:table];
        }else{
            [self.active removeTable:table andPreserveOverlays:true];
        }
    }
    [self updateClearActiveButton];
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
        case TAG_TABLE_DELETE:
            [self handleDeleteTableWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
        case TAG_CLEAR_ACTIVE:
            [self handleClearActiveWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
        case TAG_INDEX_FEATURES:
            [self handleIndexFeaturesWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
        case TAG_DELETE_INDEX_FEATURES:
            [self handleDeleteIndexFeaturesWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
        case TAG_CREATE_INDEX_FEATURES:
            [self handleCreateIndexFeaturesWithAlertView:alertView clickedButtonAtIndex:buttonIndex];
            break;
    }
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
                [self viewDatabaseOption:database];
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
                [self shareDatabaseOption:database.name];
                break;
            case 6:
                [self createFeaturesDatabaseOption:database];
                break;
            case 7:
                [self createTilesDatabaseOption:database];
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
            [options addObject:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_LINKED_TABLES_LABEL]];
            break;
        case GPKGS_TT_TILE:
            [options addObject:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_TILES_LOAD_LABEL]];
            [options addObject:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_LINKED_TABLES_LABEL]];
            break;
        case GPKGS_TT_FEATURE_OVERLAY:
            break;
        default:
            [NSException raise:@"Unsupported" format:@"Unsupported table type: %@", [GPKGSTableTypes name:sender.table.getType]];
    }
    
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:[NSString stringWithFormat:@"%@ - %@",sender.table.database,sender.table.name]
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
                        [self viewTableOption:table];
                        break;
                }
                break;
            case 1:
                switch([table getType]){
                    case GPKGS_TT_FEATURE:
                        [self editFeaturesTableOption:table];
                        break;
                    case GPKGS_TT_TILE:
                        [self editTilesTableOption:table];
                        break;
                    case GPKGS_TT_FEATURE_OVERLAY:
                        [self editFeatureOverlayTableOption:(GPKGSFeatureOverlayTable *)table];
                        break;
                }
                break;
            case 2:
                switch([table getType]){
                    case GPKGS_TT_FEATURE:
                    case GPKGS_TT_TILE:
                    case GPKGS_TT_FEATURE_OVERLAY:
                        [self deleteTableOption:table];
                        break;
                }
                break;
            case 3:
                switch([table getType]){
                    case GPKGS_TT_FEATURE:
                        [self indexFeaturesOption:table];
                        break;
                    case GPKGS_TT_TILE:
                        [self loadTilesTableOption:table];
                        break;
                    default:
                        break;
                }
                break;
            case 4:
                switch([table getType]){
                    case GPKGS_TT_FEATURE:
                        [self createFeatureTilesTableOption:table];
                        break;
                    case GPKGS_TT_TILE:
                        [self linkedTablesOption:table];
                        break;
                    default:
                        break;
                }
                break;
            case 5:
                switch([table getType]){
                    case GPKGS_TT_FEATURE:
                        [self addFeatureOverlayTableOption:table];
                        break;
                    default:
                        break;
                }
                break;
            case 6:
                switch([table getType]){
                    case GPKGS_TT_FEATURE:
                        [self linkedTablesOption:table];
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

-(void) viewDatabaseOption: (GPKGSDatabase *) database{
    [self performSegueWithIdentifier:GPKGS_MANAGER_SEG_DISPLAY_TEXT sender:database];
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
        [self.active removeDatabase:database andPreserveOverlays:false];
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
    [[alert textFieldAtIndex:0] setText:database];
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
                    [self.active renameDatabase:database asNewDatabase:newName];
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

-(void) shareDatabaseOption: (NSString *) database{
    NSString * path = [self.manager documentsPathForDatabase:database];
    if(path != nil){
        NSURL * databaseUrl = [NSURL fileURLWithPath:path];

        self.shareDocumentController = [UIDocumentInteractionController interactionControllerWithURL:databaseUrl];
        [self.shareDocumentController setUTI:@"public.database"];
        [self.shareDocumentController presentOpenInMenuFromRect:self.view.bounds inView:self.view animated:YES];
    }else{
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:[NSString stringWithFormat:@"Share Database %@", database]
                                 andMessage:[NSString stringWithFormat:@"No path was found for database %@", database]];
    }
}

-(void) createFeaturesDatabaseOption: (GPKGSDatabase *) database
{
    [self performSegueWithIdentifier:GPKGS_MANAGER_SEG_CREATE_FEATURES sender:database];
}

-(void) createTilesDatabaseOption: (GPKGSDatabase *) database
{
    [self performSegueWithIdentifier:GPKGS_MANAGER_SEG_CREATE_TILES sender:database];
}

-(void) viewTableOption: (GPKGSTable *) table{
        [self performSegueWithIdentifier:GPKGS_MANAGER_SEG_DISPLAY_TEXT sender:table];
}

-(void) editFeaturesTableOption: (GPKGSTable *) table{
    [self performSegueWithIdentifier:GPKGS_MANAGER_SEG_EDIT_FEATURES sender:table];
}

-(void) editTilesTableOption: (GPKGSTable *) table{
    [self performSegueWithIdentifier:GPKGS_MANAGER_SEG_EDIT_TILES sender:table];
}

-(void) editFeatureOverlayTableOption: (GPKGSFeatureOverlayTable *) table{
    [self performSegueWithIdentifier:GPKGS_MANAGER_SEG_EDIT_TILE_OVERLAY sender:table];
}

-(void) deleteTableOption: (GPKGSTable *) table{
    NSString * label = [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_DELETE_LABEL];
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:label
                          message:[NSString stringWithFormat:@"%@ %@ - %@?", label, table.database, table.name]
                          delegate:self
                          cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                          otherButtonTitles:label,
                          nil];
    alert.tag = TAG_TABLE_DELETE;
    objc_setAssociatedObject(alert, &ConstantKey, table, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [alert show];
}

- (void) handleDeleteTableWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex > 0){
        GPKGSTable *table = objc_getAssociatedObject(alertView, &ConstantKey);
        
        switch([table getType]){
            case GPKGS_TT_FEATURE:
            case GPKGS_TT_TILE:
                {
                    GPKGGeoPackage * geoPackage = [self.manager open:table.database];
                    @try {
                        [geoPackage deleteUserTable:table.name];
                        [self.active removeTable:table];
                        [self updateAndReloadData];
                    }
                    @catch (NSException *exception) {
                        [GPKGSUtils showMessageWithDelegate:self
                                                   andTitle:[NSString stringWithFormat:@"%@ %@ - %@ Table", [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_DELETE_LABEL], table.database, table.name]
                                                 andMessage:[NSString stringWithFormat:@"%@", [exception description]]];
                    }
                    @finally {
                        [geoPackage close];
                    }
                }
                break;
            case GPKGS_TT_FEATURE_OVERLAY:
                [self.active removeTable:table];
                [self updateAndReloadData];
                break;
        }
        
    }
}

-(void) indexFeaturesOption: (GPKGSTable *) table{
    
    BOOL geoPackageIndexed = false;
    BOOL metadataIndexed = false;
    GPKGGeoPackage * geoPackage = [self.manager open:table.database];
    @try {
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:table.name];
    
        GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
        geoPackageIndexed = [indexer isIndexedWithFeatureIndexType:GPKG_FIT_GEOPACKAGE];
        metadataIndexed = [indexer isIndexedWithFeatureIndexType:GPKG_FIT_METADATA];
    }
    @finally {
        [geoPackage close];
    }
    
    NSMutableString * geoPackageIndexLabel = [[NSMutableString alloc] initWithString:geoPackageIndexed ?
                                              [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_INDEX_DELETE_LABEL] :
                                              [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_INDEX_CREATE_LABEL]];
    [geoPackageIndexLabel appendFormat:@" %@", [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_INDEX_GEOPACKAGE_LABEL]];
    
    NSMutableString * metadataIndexLabel = [[NSMutableString alloc] initWithString:metadataIndexed ?
                                            [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_INDEX_DELETE_LABEL] :
                                            [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_INDEX_CREATE_LABEL]];
    [metadataIndexLabel appendFormat:@" %@", [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_INDEX_METADATA_LABEL]];
    
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:[NSString stringWithFormat:@"%@ - %@ %@",table.database,table.name, [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_INDEX_TITLE]]
                          message:nil
                          delegate:self
                          cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                          otherButtonTitles:geoPackageIndexLabel,
                            metadataIndexLabel,
                            nil];
    
    alert.tag = TAG_INDEX_FEATURES;
    
    objc_setAssociatedObject(alert, &ConstantKey, table, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    
    [alert show];
}

- (void) handleIndexFeaturesWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex > 0){
        
        GPKGSTable *table = objc_getAssociatedObject(alertView, &ConstantKey);
        
        enum GPKGFeatureIndexType indexLocation = GPKG_FIT_NONE;
        switch(buttonIndex){
            case 1:
                indexLocation = GPKG_FIT_GEOPACKAGE;
                break;
            case 2:
                indexLocation = GPKG_FIT_METADATA;
                break;
            default:
                break;
        }
        
        GPKGSTableIndex * tableIndex = [[GPKGSTableIndex alloc] initWithTable:table andIndexLocation:indexLocation];
        [self createOrDeleteFeatureIndexWithTableIndex:tableIndex];
    }
}

- (void) createOrDeleteFeatureIndexWithTableIndex: (GPKGSTableIndex *) tableIndex{
    BOOL indexed = false;
    GPKGGeoPackage * geoPackage = [self.manager open:tableIndex.table.database];
    @try {
        GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:tableIndex.table.name];
        GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
        indexed = [indexer isIndexedWithFeatureIndexType:tableIndex.indexLocation];
    }
    @finally {
        [geoPackage close];
    }
    if(indexed){
        [self deleteFeatureIndexWithTableIndex:tableIndex];
    }else{
        [self createFeatureIndexWithTableIndex:tableIndex];
    }
}

- (void) deleteFeatureIndexWithTableIndex: (GPKGSTableIndex *) tableIndex{
    NSString * title = [NSString stringWithFormat:@"%@ %@", [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_INDEX_DELETE_LABEL],
                        [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_INDEX_TITLE]];
    NSMutableString * message = [[NSMutableString alloc] initWithFormat:@"%@ %@ - %@ %@",
                                 [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_INDEX_DELETE_LABEL],
                                 tableIndex.table.database,
                                 tableIndex.table.name,
                                 [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_INDEX_TITLE]];
    switch(tableIndex.indexLocation){
        case GPKG_FIT_GEOPACKAGE:
            [message appendFormat:@" %@", [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_INDEX_DELETE_GEOPACKAGE_LABEL]];
            break;
        case GPKG_FIT_METADATA:
            [message appendFormat:@" %@", [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_INDEX_DELETE_METADATA_LABEL]];
            break;
        default:
            break;
    }
    UIAlertView * alert = [[UIAlertView alloc]
                           initWithTitle:title
                           message:message
                           delegate:self
                           cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                           otherButtonTitles:[GPKGSProperties getValueOfProperty:GPKGS_PROP_OK_LABEL],
                           nil];
    alert.tag = TAG_DELETE_INDEX_FEATURES;
    objc_setAssociatedObject(alert, &ConstantKey, tableIndex, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [alert show];
}

- (void) handleDeleteIndexFeaturesWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex > 0){
        
        GPKGSTableIndex *tableIndex = objc_getAssociatedObject(alertView, &ConstantKey);
        
        GPKGGeoPackage * geoPackage = [self.manager open:tableIndex.table.database];
        @try {
            GPKGFeatureDao * featureDao = [geoPackage getFeatureDaoWithTableName:tableIndex.table.name];
            GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
            [indexer setIndexLocation:tableIndex.indexLocation];
            [indexer deleteIndex];
        }
        @finally {
            [geoPackage close];
        }
    }
}

- (void) createFeatureIndexWithTableIndex: (GPKGSTableIndex *) tableIndex{
    NSString * title = [NSString stringWithFormat:@"%@ %@", [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_INDEX_CREATE_LABEL],
                        [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_INDEX_TITLE]];
    NSMutableString * message = [[NSMutableString alloc] initWithFormat:@"%@ %@ - %@ %@",
                                 [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_INDEX_CREATE_LABEL],
                                 tableIndex.table.database,
                                 tableIndex.table.name,
                                 [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_INDEX_TITLE]];
    switch(tableIndex.indexLocation){
        case GPKG_FIT_GEOPACKAGE:
            [message appendFormat:@" %@", [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_INDEX_CREATE_GEOPACKAGE_LABEL]];
            break;
        case GPKG_FIT_METADATA:
            [message appendFormat:@" %@", [GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_INDEX_FEATURES_INDEX_CREATE_METADATA_LABEL]];
            break;
        default:
            break;
    }
    UIAlertView * alert = [[UIAlertView alloc]
                           initWithTitle:title
                           message:message
                           delegate:self
                           cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                           otherButtonTitles:[GPKGSProperties getValueOfProperty:GPKGS_PROP_OK_LABEL],
                           nil];
    alert.tag = TAG_CREATE_INDEX_FEATURES;
    objc_setAssociatedObject(alert, &ConstantKey, tableIndex, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [alert show];
}

- (void) handleCreateIndexFeaturesWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex > 0){
        GPKGSTableIndex *tableIndex = objc_getAssociatedObject(alertView, &ConstantKey);
        [GPKGSIndexerTask indexFeaturesWithCallback:self andDatabase:tableIndex.table.database andTable:tableIndex.table.name andFeatureIndexType:tableIndex.indexLocation];
    }
}

-(void) linkedTablesOption: (GPKGSTable *) table{
    [self performSegueWithIdentifier:GPKGS_MANAGER_SEG_LINKED_TABLES sender:table];
}

-(void) loadTilesTableOption: (GPKGSTable *) table{
    [self performSegueWithIdentifier:GPKGS_MANAGER_SEG_LOAD_TILES sender:table];
}

-(void) createFeatureTilesTableOption: (GPKGSTable *) table{
    [self performSegueWithIdentifier:GPKGS_MANAGER_SEG_CREATE_FEATURE_TILES sender:table];
}

-(void) addFeatureOverlayTableOption: (GPKGSTable *) table{
    [self performSegueWithIdentifier:GPKGS_MANAGER_SEG_ADD_TILE_OVERLAY sender:table];
}


/* DownlaodCoordinator completion delegate method */
-(void)downloadCoordinatorCompletitonHandler:(bool)didDownload {
    [self.parentViewController dismissViewControllerAnimated:YES completion:nil];
    [_childCoordinators removeLastObject]; // TODO: make this choose the right one
    [self updateAndReloadData];
}



- (IBAction)downloadFile:(id)sender {
    NSLog(@"Download button tapped");
    
    UINavigationController *navController = [[UINavigationController alloc] init];
    [self.parentViewController presentViewController:navController animated:NO completion:nil];
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

- (IBAction)expandAll:(id)sender {
    for(GPKGSDatabase * database in [self.databases allValues]){
        database.expanded = true;
        [self addExpandedSetting:database.name];
    }
    [self updateAndReloadData];
}

- (IBAction)collapseAll:(id)sender {
    for(GPKGSDatabase * database in [self.databases allValues]){
        database.expanded = false;
    }
    [self clearExpandedSettings];
    [self updateAndReloadData];
}

- (IBAction)clearActive:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:nil
                          message:[NSString stringWithFormat:@"%@ - %d", [GPKGSProperties getValueOfProperty:GPKGS_PROP_CLEAR_ACTIVE_LABEL], [self.active getActiveTableCount]]
                          delegate:self
                          cancelButtonTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]
                          otherButtonTitles:[GPKGSProperties getValueOfProperty:GPKGS_PROP_OK_LABEL],
                          nil];
    alert.tag = TAG_CLEAR_ACTIVE;
    [alert show];
}

- (void) handleClearActiveWithAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if(buttonIndex > 0){
        [self.active clearActive];
        [self updateAndReloadData];
    }
}

-(void) updateClearActiveButton{
    if([self.active getActiveTableCount] > 0){
        [GPKGSUtils enableButton:self.clearActiveButton];
    }else{
        [GPKGSUtils disableButton:self.clearActiveButton];
    }
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

- (void)createFeaturesViewController:(GPKGSCreateFeaturesViewController *)controller createdFeatures:(BOOL)created withError: (NSString *) error{
    if(created){
        [self updateAndReloadData];
    }
    if(error != nil){
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_CREATE_FEATURES_LABEL]
                                 andMessage:[NSString stringWithFormat:@"Error creating features table '%@' in database: '%@'\n\nError: %@", controller.nameValue.text, controller.database.name, error]];
    }
}

- (void)createManagerTilesViewController:(GPKGSManagerCreateTilesViewController *)controller createdTiles:(int)count withError: (NSString *) error{
    [self updateAndReloadData];
    if(count > 0){
        self.retainModifiedForMap = true;
        [self.active setModified:true];
    }
    if(error != nil){
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_CREATE_TILES_LABEL]
                                 andMessage:[NSString stringWithFormat:@"Error creating tiles table '%@' in database: '%@'\n\nError: %@", controller.data.name, controller.database.name, error]];
    }
}

- (void)loadManagerTilesViewController:(GPKGSManagerLoadTilesViewController *)controller loadedTiles:(int)count withError: (NSString *) error{
    [self updateAndReloadData];
    if(count > 0){
        self.retainModifiedForMap = true;
        [self.active setModified:true];
    }
    if(error != nil){
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_TILES_LOAD_LABEL]
                                 andMessage:[NSString stringWithFormat:@"Error loading tiles into table '%@' in database: '%@'\n\nError: %@", controller.table.name, controller.table.database, error]];
    }
}

- (void)editFeaturesViewController:(GPKGSEditFeaturesViewController *)controller editedFeatures:(BOOL)edited withError: (NSString *) error{
    if(edited){
        [self updateAndReloadData];
    }
}

- (void)editTilesViewController:(GPKGSEditTilesViewController *)controller tilesEdited:(BOOL)edited{
    if(edited){
        [self updateAndReloadData];
        self.retainModifiedForMap = true;
        [self.active setModified:true];
    }
}

- (void)createFeatureTilesViewController:(GPKGSCreateFeatureTilesViewController *)controller createdTiles:(int)count withError: (NSString *) error{
    [self updateAndReloadData];
    if(count > 0){
        self.retainModifiedForMap = true;
        [self.active setModified:true];
    }
    if(error != nil){
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_CREATE_FEATURE_TILES_LABEL]
                                 andMessage:[NSString stringWithFormat:@"Error creating feature tiles table '%@' for feature table '%@' in database: '%@'\n\nError: %@", controller.nameValue.text, controller.name, controller.database, error]];
    }
}

- (void)addTileOverlayViewController:(GPKGSAddTileOverlayViewController *)controller featureOverlayTable:(GPKGSFeatureOverlayTable *)featureOverlayTable{
    if([self.active exists:featureOverlayTable]){
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_ADD_FEATURE_OVERLAY_LABEL]
                                 andMessage:[NSString stringWithFormat:@"Feature overlay '%@' already exists in database '%@'. Could not create for feature table '%@'", controller.nameValue.text, controller.table.database, controller.table.name]];
    }else{
        self.retainModifiedForMap = true;
        [self.active addTable:featureOverlayTable];
        [self updateAndReloadData];
    }
}

- (void)editTileOverlayViewController:(GPKGSManagerEditTileOverlayViewController *)controller featureOverlayTable:(GPKGSFeatureOverlayTable *)featureOverlayTable{
    self.retainModifiedForMap = true;
    [self.active removeTable:featureOverlayTable];
    [self.active addTable:featureOverlayTable];
    [self updateAndReloadData];
}

- (void)linkedTablesViewController:(GPKGSLinkedTablesViewController *)controller linksEdited:(BOOL)edited withError: (NSString *) error{
    if(edited){
        self.retainModifiedForMap = true;
        [self.active setModified:true];
    }
    if(error != nil){
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_TABLE_LINKED_TABLES_LABEL]
                                 andMessage:[NSString stringWithFormat:@"Error editing linked tables for table '%@' in database: '%@'\n\nError: %@", controller.table.name, controller.table.database, error]];
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if([segue.identifier isEqualToString:GPKGS_MANAGER_SEG_DOWNLOAD_FILE])
    {
        GPKGSDownloadFileViewController *downloadFileViewController = segue.destinationViewController;
        downloadFileViewController.delegate = self;
        
    }else if([segue.identifier isEqualToString:GPKGS_MANAGER_SEG_DISPLAY_TEXT]){
        GPKGSDisplayTextViewController *displayTextViewController = segue.destinationViewController;
        if([sender isKindOfClass:[GPKGSDatabase class]]){
            GPKGSDatabase * database = (GPKGSDatabase *)sender;
            displayTextViewController.database = database;
        }else if([sender isKindOfClass:[GPKGSTable class]]){
            GPKGSTable * table = (GPKGSTable *)sender;
            displayTextViewController.table = table;
        }
    }else if([segue.identifier isEqualToString:GPKGS_MANAGER_SEG_CREATE_FEATURES]){
        GPKGSCreateFeaturesViewController *createFeaturesViewController = segue.destinationViewController;
        GPKGSDatabase * database = (GPKGSDatabase *)sender;
        createFeaturesViewController.delegate = self;
        createFeaturesViewController.database = database;
        createFeaturesViewController.manager = self.manager;
    }else if([segue.identifier isEqualToString:GPKGS_MANAGER_SEG_CREATE_TILES]){
        GPKGSManagerCreateTilesViewController *createTilesViewController = segue.destinationViewController;
        GPKGSDatabase * database = (GPKGSDatabase *)sender;
        createTilesViewController.delegate = self;
        createTilesViewController.database = database;
        createTilesViewController.manager = self.manager;
        createTilesViewController.data = [[GPKGSCreateTilesData alloc] init];
    }else if([segue.identifier isEqualToString:GPKGS_MANAGER_SEG_LOAD_TILES]){
        GPKGSManagerLoadTilesViewController *loadTilesViewController = segue.destinationViewController;
        GPKGSTable * table = (GPKGSTable *)sender;
        loadTilesViewController.delegate = self;
        loadTilesViewController.table = table;
        loadTilesViewController.manager = self.manager;
        loadTilesViewController.data = [[GPKGSLoadTilesData alloc] init];
    }else if([segue.identifier isEqualToString:GPKGS_MANAGER_SEG_EDIT_FEATURES]){
        GPKGSEditFeaturesViewController *editFeaturesViewController = segue.destinationViewController;
        GPKGSTable * table = (GPKGSTable *)sender;
        editFeaturesViewController.table = table;
        editFeaturesViewController.manager = self.manager;
        editFeaturesViewController.delegate = self;
    }else if([segue.identifier isEqualToString:GPKGS_MANAGER_SEG_EDIT_TILES]){
        GPKGSEditTilesViewController *editTilesViewController = segue.destinationViewController;
        GPKGSTable * table = (GPKGSTable *)sender;
        editTilesViewController.delegate = self;
        editTilesViewController.table = table;
        editTilesViewController.manager = self.manager;
    }else if([segue.identifier isEqualToString:GPKGS_MANAGER_SEG_CREATE_FEATURE_TILES]){
        GPKGSCreateFeatureTilesViewController *createFeatureTilesViewController = segue.destinationViewController;
        GPKGSTable * table = (GPKGSTable *)sender;
        createFeatureTilesViewController.delegate = self;
        createFeatureTilesViewController.database = table.database;
        createFeatureTilesViewController.name = table.name;
        createFeatureTilesViewController.manager = self.manager;
        createFeatureTilesViewController.featureTilesDrawData = [[GPKGSFeatureTilesDrawData alloc] init];
        createFeatureTilesViewController.generateTilesData =  [[GPKGSGenerateTilesData alloc] init];
    }else if([segue.identifier isEqualToString:GPKGS_MANAGER_SEG_ADD_TILE_OVERLAY]){
        GPKGSAddTileOverlayViewController *addTileOverlayViewController = segue.destinationViewController;
        GPKGSTable * table = (GPKGSTable *)sender;
        addTileOverlayViewController.delegate = self;
        addTileOverlayViewController.table = table;
        addTileOverlayViewController.manager = self.manager;
    }else if([segue.identifier isEqualToString:GPKGS_MANAGER_SEG_EDIT_TILE_OVERLAY]){
        GPKGSManagerEditTileOverlayViewController *editTileOverlayViewController = segue.destinationViewController;
        GPKGSFeatureOverlayTable * table = (GPKGSFeatureOverlayTable *)sender;
        editTileOverlayViewController.delegate = self;
        editTileOverlayViewController.table = table;
        editTileOverlayViewController.manager = self.manager;
    }else if([segue.identifier isEqualToString:GPKGS_MANAGER_SEG_LINKED_TABLES]){
        GPKGSLinkedTablesViewController *linkedTablesViewController = segue.destinationViewController;
        GPKGSTable * table = (GPKGSTable *)sender;
        linkedTablesViewController.delegate = self;
        linkedTablesViewController.table = table;
        linkedTablesViewController.manager = self.manager;
    }
    
}

-(void) addExpandedSetting: (NSString *) database{
    NSArray * expandedDatabases = [self.settings stringArrayForKey:GPKGS_EXPANDED_PREFERENCE];
    if(expandedDatabases == nil){
        NSMutableArray * newExpandedDatabases = [[NSMutableArray alloc] initWithObjects:database, nil];
        [self.settings setObject:newExpandedDatabases forKey:GPKGS_EXPANDED_PREFERENCE];
        [self.settings synchronize];
    }else{
        NSMutableArray * newExpandedDatabases = [[NSMutableArray alloc] initWithArray:expandedDatabases];
        if(![newExpandedDatabases containsObject:database]){
            [newExpandedDatabases addObject:database];
            [self.settings setObject:newExpandedDatabases forKey:GPKGS_EXPANDED_PREFERENCE];
            [self.settings synchronize];
        }
    }
}

-(void) removeExpandedSetting: (NSString *) database{
    NSArray * expandedDatabases = [self.settings stringArrayForKey:GPKGS_EXPANDED_PREFERENCE];
    if(expandedDatabases != nil && [expandedDatabases containsObject:database]){
        NSMutableArray * newExpandedDatabases = [[NSMutableArray alloc] initWithArray:expandedDatabases];
        [newExpandedDatabases removeObject:database];
        [self.settings setObject:newExpandedDatabases forKey:GPKGS_EXPANDED_PREFERENCE];
        [self.settings synchronize];
    }
}

-(void) clearExpandedSettings{
    [self.settings removeObjectForKey:GPKGS_EXPANDED_PREFERENCE];
    [self.settings synchronize];
}

-(void) onIndexerCanceled: (NSString *) result{
    
}

-(void) onIndexerFailure: (NSString *) result{
    
}

-(void) onIndexerCompleted: (int) count{
    
}

@end
