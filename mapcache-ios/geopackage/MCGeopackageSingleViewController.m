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
@property (nonatomic, strong) MCDatabases *active;
@property (nonatomic) BOOL haveScrolled;
@end

@implementation MCGeopackageSingleViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    self.manager = [GPKGGeoPackageFactory manager];
    self.active = [MCDatabases getInstance];
    
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
    self.haveScrolled = NO;
    
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
    
    for (MCTable *table in tables) {
        MCLayerCell *layerCell = [self.tableView dequeueReusableCellWithIdentifier:@"layerCell"];
        NSString *typeImageName = @"";
        
        if ([table isMemberOfClass:[MCFeatureTable class]]) {
            typeImageName = [MCProperties getValueOfProperty:GPKGS_PROP_ICON_GEOMETRY];
            [layerCell.detailLabel setText: [NSString stringWithFormat:@"%d features", [(MCFeatureTable *)table count]]];
        } else if ([table isMemberOfClass:[MCTileTable class]]) {
            typeImageName = [MCProperties getValueOfProperty:GPKGS_PROP_ICON_TILES];
            [layerCell.detailLabel setText:[NSString stringWithFormat:@"Zoom levels %d - %d",  [(MCTileTable *)table minZoom], [(MCTileTable *)table maxZoom]]];
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
            [self.delegate updateDatabase];
        }
    }
}


- (void) closeDrawer {
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
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    // TODO add layer details view
    /*if([cellObject isKindOfClass:[MCLayerCell class]]){
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
    }*/
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
        toggleAction.title = @"Show on map";
    } else {
        toggleAction.backgroundColor = [UIColor grayColor];
        toggleAction.title = @"Hide from map";
    }
    
    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:@[toggleAction]];
    configuration.performsFirstActionWithFullSwipe = YES;
    return configuration;
}



- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        MCLayerCell *cell = [_cellArray objectAtIndex:indexPath.row];
        [_delegate deleteLayer:cell.table];
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
        [MCUtils showMessageWithDelegate:self
                                   andTitle:[NSString stringWithFormat:@"Share Database %@", _database]
                                 andMessage:[NSString stringWithFormat:@"No path was found for database %@", _database]];
    }
}


- (void) renameGeoPackage {
    NSLog(@"Renaming GeoPackage");
    
    UIAlertController *renameAlert = [UIAlertController alertControllerWithTitle:@"Rename" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [renameAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = self.database.name;
        [textField addTarget:self action:@selector(alertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
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
                    [MCUtils showMessageWithDelegate:self
                                               andTitle:[MCProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_RENAME_LABEL]
                                             andMessage:[NSString stringWithFormat:@"Rename from %@ to %@ was not successful", self.database.name, newName]];
                }
            }
            @catch (NSException *exception) {
                [MCUtils showMessageWithDelegate:self
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
        [textField addTarget:self action:@selector(alertTextFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
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
                    [MCUtils showMessageWithDelegate:self
                                               andTitle:[MCProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_COPY_LABEL]
                                             andMessage:[NSString stringWithFormat:@"Copy from %@ to %@ was not successful", database, newName]];
                }
            }
            @catch (NSException *exception) {
                [MCUtils showMessageWithDelegate:self
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


// Override this method to make the drawer and the scrollview play nice
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.haveScrolled) {
        [self rollUpPanGesture:scrollView.panGestureRecognizer withScrollView:scrollView];
    }
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.haveScrolled = YES;
    
    if (!self.isFullView) {
        scrollView.scrollEnabled = NO;
        scrollView.scrollEnabled = YES;
    } else {
        scrollView.scrollEnabled = YES;
    }
}


/* Chekcing */
- (void)alertTextFieldDidChange:(UITextField *)sender
{
    UIAlertController *alertController = (UIAlertController *)self.presentedViewController;
    if (alertController)
    {
        UITextField *textField = alertController.textFields.firstObject;
        UIAlertAction *okAction = alertController.actions.firstObject;
        NSString *fieldValue = textField.text;
        
        okAction.enabled = YES;
        
        if (fieldValue.length == 0) {
            okAction.enabled = NO;
        } else {
            for (NSString* name in [self.manager databases]) {
                if ([fieldValue isEqualToString:name]) {
                    okAction.enabled = NO;
                    break;
                }
            }
        }
    }
}


@end

