//
//  GPKGSGeopackageSingleViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/31/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "MCGeopackageSingleViewController.h"

@interface MCGeopackageSingleViewController ()
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIDocumentInteractionController *shareDocumentController;
@property (nonatomic, strong) GPKGSDatabases *active;
@end

@implementation MCGeopackageSingleViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    self.manager = [GPKGGeoPackageFactory getManager];
    self.active = [GPKGSDatabases getInstance];
    
    CGRect bounds = self.view.bounds;
    CGRect insetBounds = CGRectMake(bounds.origin.x, bounds.origin.y + 32, bounds.size.width, bounds.size.height - 20);
    self.tableView = [[UITableView alloc] initWithFrame: insetBounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 390.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    [self registerCellTypes];
    [self initCellArray];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    UIEdgeInsets tabBarInsets = UIEdgeInsetsMake(0, 0, self.tabBarController.tabBar.frame.size.height, 0);
    self.tableView.contentInset = tabBarInsets;
    self.tableView.scrollIndicatorInsets = tabBarInsets;
    
    [self.view addSubview:self.tableView];
    [self addDragHandle];
    [self addCloseButton];
}


- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void) initCellArray {
    if ([_cellArray count] > 0) {
        [_cellArray removeAllObjects];
    }
    
    MCHeaderCell *headerCell = [self.tableView dequeueReusableCellWithIdentifier:@"header"];
    headerCell.nameLabel.text = _database.name;
    
    NSLog(@"GeoPackage Size %@", [self.manager readableSize:_database.name]);
    headerCell.detailLabelOne.text = [self.manager readableSize:_database.name]; // TODO look into threading this
    
    NSInteger tileCount = [_database getTileCount];
    NSString *tileText = tileCount == 1 ? @"tile layer" : @"tile layers";
    headerCell.detailLabelTwo.text = [NSString stringWithFormat:@"%ld %@", tileCount, tileText];
    
    NSInteger featureCount = [_database getFeatureCount];
    NSString *featureText = featureCount == 1 ? @"feature layer" : @"feature layers";
    headerCell.detailLabelThree.text = [NSString stringWithFormat:@"%ld %@", featureCount, featureText];
    
    MCGeoPackageOperationsCell *geoPackageOperationsCell = [self.tableView dequeueReusableCellWithIdentifier:@"operations"];
    geoPackageOperationsCell.delegate = self;
    
    MCSectionTitleCell *layersTitleCell = [self.tableView dequeueReusableCellWithIdentifier:@"sectionTitle"];
    layersTitleCell.sectionTitleLabel.text = @"Layers";

    // TODO: Convert new layer wizard to work with drawer system for a future release
    MCButtonCell *newLayerButtonCell = [self.tableView dequeueReusableCellWithIdentifier:@"buttonCell"];
    [newLayerButtonCell.button setTitle:@"New Layer" forState:UIControlStateNormal];
    newLayerButtonCell.action = GPKGS_ACTION_NEW_LAYER;
    newLayerButtonCell.delegate = self;
    
    _cellArray = [[NSMutableArray alloc] initWithObjects: headerCell, geoPackageOperationsCell, layersTitleCell, newLayerButtonCell, nil];
    NSArray *tables = [_database getTables];
    
    for (GPKGSTable *table in tables) {
        MCLayerCell *layerCell = [self.tableView dequeueReusableCellWithIdentifier:@"layerCell"];
        NSString *typeImageName = @"";
        
        if ([table isMemberOfClass:[GPKGSFeatureTable class]]) {
            typeImageName = [GPKGSProperties getValueOfProperty:GPKGS_PROP_ICON_GEOMETRY];
        } else if ([table isMemberOfClass:[GPKGSTileTable class]]) {
            typeImageName = [GPKGSProperties getValueOfProperty:GPKGS_PROP_ICON_TILES];
        }
        
        layerCell.table = table;
        layerCell.layerNameLabel.text = table.name;
        [layerCell.layerTypeImage setImage:[UIImage imageNamed:typeImageName]];
        
        if ([_active exists:table]) {
            [layerCell activeIndicatorOn];
        } else {
            [layerCell activeIndicatorOff];
        }
        
        [_cellArray addObject:layerCell];
    }
    
    // TODO: add section for reference systems
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCHeaderCellDisplay" bundle:nil] forCellReuseIdentifier:@"header"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCGeoPackageOperationsCell" bundle:nil] forCellReuseIdentifier:@"operations"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCSectionTitleCell" bundle:nil] forCellReuseIdentifier:@"sectionTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCLayerCell" bundle:nil] forCellReuseIdentifier:@"layerCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCButtonCell" bundle:nil] forCellReuseIdentifier:@"buttonCell"];
}


- (void) update {
    GPKGGeoPackage *geoPackage = nil;
    GPKGSDatabase *updatedDatabase = nil;
    
    @try {
        geoPackage = [_manager open:_database.name];
        
        GPKGContentsDao *contentsDao = [geoPackage getContentsDao];
        NSMutableArray *tables = [[NSMutableArray alloc] init];
        
        updatedDatabase = [[GPKGSDatabase alloc] initWithName:_database.name andExpanded:false];
        
        // Handle the Feature Layers
        for (NSString *tableName in [geoPackage getFeatureTables]) {
            GPKGFeatureDao *featureDao = [geoPackage getFeatureDaoWithTableName:tableName];
            int count = [featureDao count];
            
            GPKGContents *contents = (GPKGContents *)[contentsDao queryForIdObject:tableName];
            GPKGGeometryColumns *geometryColumns = [contentsDao getGeometryColumns:contents];
            enum SFGeometryType geometryType = [SFGeometryTypes fromName:geometryColumns.geometryTypeName];
            
            GPKGSFeatureTable *table = [[GPKGSFeatureTable alloc] initWithDatabase:_database.name andName:tableName andGeometryType:geometryType andCount:count];
            // there was some bit about setting the table as active, but I think that was for the OG manager
            
            [tables addObject:table];
            [updatedDatabase addFeature:table];
            // there was a bit about expanding the cells to add another to the manager for the new feaure layer, but that might get handled in this case by just calling initCells
        }
        
        // Handle the tile layers
        for (NSString *tableName in [geoPackage getTileTables]) {
            GPKGTileDao *tileDao = [geoPackage getTileDaoWithTableName:tableName];
            int count = [tileDao count];
            
            GPKGSTileTable *table = [[GPKGSTileTable alloc] initWithDatabase:_database.name andName:tableName andCount:count];
            // skipping active setting, that will be handled on the new map
            [tables addObject:table];
            [updatedDatabase addTile:table];
        }
        
        // TODO: Figure out what to do about overlays
    }
    @finally {
        
        
        if (geoPackage == nil) {
            @try {
                [_manager delete:_database.name];
            }
            @catch (NSException *exception) {
            }
        } else {
            if (updatedDatabase != nil) {
                _database = updatedDatabase;
            }
            [geoPackage close];
        }
    }
    
    [self initCellArray]; // May not need to call this, or may need to call it closer to the end
    [self.tableView reloadData];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.isMovingFromParentViewController) {
        [_delegate callCompletionHandler];
    }
}


- (void) removeLayerNamed:(NSString *)layerName {
    UITableViewCell *cell;
    
    for (int i = 0; i <  _cellArray.count; i++) {
        cell = [_cellArray objectAtIndex:i];
        
        if ([cell isKindOfClass:[MCLayerCell class]] && [((MCLayerCell *)cell).layerNameLabel.text isEqualToString:layerName]) {
            [_cellArray removeObject:cell];
            [self update];
        }
    }
}


- (void) closeDrawer {
    [super closeDrawer];
    [self.drawerViewDelegate popDrawer];
    [self.delegate callCompletionHandler];
}


#pragma mark - TableView delegate methods
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [_cellArray objectAtIndex:indexPath.row];
}


- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cellArray count];
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[_cellArray objectAtIndex:indexPath.row] isKindOfClass:[MCLayerCell class]]) {
        return YES;
    } else {
        return NO;
    }
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    MCLayerCell *layerCell;
    NSObject *cellObject = [_cellArray objectAtIndex:indexPath.row];
    
    if([cellObject isKindOfClass:[MCLayerCell class]]){
        layerCell = (MCLayerCell *) cellObject;
        NSString *layerName = layerCell.layerNameLabel.text;
        GPKGGeoPackage *geoPackage = [_manager open:_database.name];
        
        if ([geoPackage isFeatureTable:layerName]) {
            GPKGFeatureDao *featureDao =  [geoPackage getFeatureDaoWithTableName:layerName];
            [_delegate showLayerDetails:featureDao];
            [geoPackage close];
        } else if ([geoPackage isTileTable:layerName]) {
            GPKGTileDao *tileDao =  [geoPackage getTileDaoWithTableName:layerName];
            [_delegate showLayerDetails:tileDao];
            [geoPackage close];
        }
    }
}


- (UISwipeActionsConfiguration *) tableView:(UITableView *)tableView leadingSwipeActionsConfigurationForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    MCLayerCell *cell = (MCLayerCell *)[_cellArray objectAtIndex:indexPath.row];
    
    UIContextualAction *toggleAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Add to map" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        [self.delegate toggleLayer: cell.table];
        [cell toggleActiveIndicator];
        completionHandler(YES);
    }];
    
    if ([cell.activeIndicator isHidden]) {
        toggleAction.backgroundColor = [UIColor colorWithRed:0.13 green:0.31 blue:0.48 alpha:1.0];
        toggleAction.title = @"Add to map";
    } else {
        toggleAction.backgroundColor = [UIColor grayColor];
        toggleAction.title = @"Remove from map";
    }
    
    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:@[toggleAction]];
    configuration.performsFirstActionWithFullSwipe = YES;
    return configuration;
}



- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        MCLayerCell *cell = [_cellArray objectAtIndex:indexPath.row];
        NSString *layerName = cell.layerNameLabel.text;
        [_delegate deleteLayer:layerName];
        completionHandler(YES);
    }];
    
    deleteAction.backgroundColor = [UIColor redColor];
    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:@[deleteAction]];
    configuration.performsFirstActionWithFullSwipe = YES;
    return configuration;
}


#pragma mark - Cell delegate methods
-(void) deleteGeoPackage {
    NSLog(@"Deleting GeoPackage...");
    
    UIAlertController *deleteAlert = [UIAlertController alertControllerWithTitle:@"Delete" message:@"Do you want to delete this GeoPackage? This action can not be undone." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirmDelete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self.delegate deleteGeoPackage];
        [self.drawerViewDelegate popDrawer];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [deleteAlert dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [deleteAlert addAction:confirmDelete];
    [deleteAlert addAction:cancel];
    
    [self presentViewController:deleteAlert animated:YES completion:nil];
}


- (void) shareGeoPackage {
    NSLog(@"Sharing GeoPackage");
    NSString * path = [self.manager documentsPathForDatabase:_database.name];
    if(path != nil){
        NSURL * databaseUrl = [NSURL fileURLWithPath:path];
        
        _shareDocumentController = [UIDocumentInteractionController interactionControllerWithURL:databaseUrl];
        [_shareDocumentController setUTI:@"public.database"];
        [_shareDocumentController presentOpenInMenuFromRect:self.view.bounds inView:self.view animated:YES];
    }else{
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:[NSString stringWithFormat:@"Share Database %@", _database]
                                 andMessage:[NSString stringWithFormat:@"No path was found for database %@", _database]];
    }
}


- (void) renameGeoPackage {
    NSLog(@"Renaming GeoPackage");
    
    UIAlertController *renameAlert = [UIAlertController alertControllerWithTitle:@"Rename" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [renameAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = self.database.name;
    }];
    
    UIAlertAction *confirmRename = [UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"New name is: %@", renameAlert.textFields[0].text);
        
        NSString * newName = renameAlert.textFields[0].text;
        
        if(newName != nil && [newName length] > 0 && ![newName isEqualToString:self.database.name]){
            @try {
                if([self.manager rename:self.database.name to:newName]){
                    self.database.name = newName;
                    [self initCellArray];
                    [self.tableView reloadData];
                }else{
                    [GPKGSUtils showMessageWithDelegate:self
                                               andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_RENAME_LABEL]
                                             andMessage:[NSString stringWithFormat:@"Rename from %@ to %@ was not successful", self.database.name, newName]];
                }
            }
            @catch (NSException *exception) {
                [GPKGSUtils showMessageWithDelegate:self
                                           andTitle:[NSString stringWithFormat:@"Rename %@ to %@", self.database.name, newName]
                                         andMessage:[NSString stringWithFormat:@"%@", [exception description]]];
            }
        }
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [renameAlert dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [renameAlert addAction:confirmRename];
    [renameAlert addAction:cancel];
    
    [self presentViewController:renameAlert animated:YES completion:nil];
}


- (void) copyGeoPackage {
    UIAlertController *copyAlert = [UIAlertController alertControllerWithTitle:@"Copy" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [copyAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = [NSString stringWithFormat:@"%@_copy", self.database.name];
    }];
    
    UIAlertAction *confirmCopy = [UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString * newName = [copyAlert.textFields[0] text];
        NSString *database = self.database.name;
        if(newName != nil && [newName length] > 0 && ![newName isEqualToString:database]){
            @try {
                if([self.manager copy:database to:newName]){
                    NSLog(@"Copy Successful");
                    UIAlertController *confirmation = [UIAlertController alertControllerWithTitle:@"Success" message:@"Copy created." preferredStyle:UIAlertControllerStyleAlert];
                    [self presentViewController:confirmation animated:YES completion:nil];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [confirmation dismissViewControllerAnimated:YES completion:nil];
                        [self.delegate copyGeoPackage];
                    });
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
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [copyAlert dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [copyAlert addAction:confirmCopy];
    [copyAlert addAction:cancel];
    
    [self presentViewController:copyAlert animated:YES completion:nil];
}


- (void)performButtonAction:(NSString *) action {
    NSLog(@"Button pressed, checking action...");
    
    if ([action isEqualToString:GPKGS_ACTION_NEW_LAYER]) {
        NSLog(@"Button pressed, handling action %@", action);
        [_delegate newLayer];
    }
}


@end
