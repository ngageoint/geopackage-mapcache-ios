//
//  MCLayerViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 7/3/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCLayerViewController.h"

@interface MCLayerViewController ()
@property (strong, nonatomic) NSMutableArray *cellArray;
@property (strong, nonatomic) MCFeatureTable *featureTable;
@property (strong, nonatomic) MCTileTable *tileTable;
@property (strong, nonatomic) GPKGGeoPackageManager *manager;
@property (strong, nonatomic) UITableView *tableView;
@property (nonatomic) BOOL haveScrolled;
@property (nonatomic) CGFloat contentOffset;
@end

@implementation MCLayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect bounds = self.view.bounds;
    CGRect insetBounds = CGRectMake(bounds.origin.x, bounds.origin.y + 32, bounds.size.width, bounds.size.height - 20);
    self.tableView = [[UITableView alloc] initWithFrame: insetBounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 141.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    
    [self registerCellTypes];
    [self initCellArray];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    UIEdgeInsets tabBarInsets = UIEdgeInsetsMake(0, 0, self.tabBarController.tabBar.frame.size.height, 0);
    self.tableView.contentInset = tabBarInsets;
    self.tableView.scrollIndicatorInsets = tabBarInsets;
    [self addAndConstrainSubview:self.tableView];
    [self addDragHandle];
    [self addCloseButton];
    self.contentOffset = 0;
    self.haveScrolled = NO;
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCHeaderCellDisplay" bundle:nil] forCellReuseIdentifier:@"header"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCFeatureLayerOperationsCell" bundle:nil] forCellReuseIdentifier:@"featureButtons"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTileLayerOperationsCell" bundle:nil] forCellReuseIdentifier:@"tileButtons"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCLayerCell" bundle: nil] forCellReuseIdentifier:@"field"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCButtonCell" bundle: nil] forCellReuseIdentifier:@"button"];
}


- (void) initCellArray {
    _cellArray = [[NSMutableArray alloc] init];
    
    if ([self.table isKindOfClass:MCTileTable.class]) {
        self.tileTable = (MCTileTable *) self.table;
    } else if ([self.table isKindOfClass:MCFeatureTable.class]) {
        self.featureTable = (MCFeatureTable *) self.table;
    }
    
    MCHeaderCell *headerCell = [self.tableView dequeueReusableCellWithIdentifier:@"header"];
    headerCell.nameLabel.text = self.table.name;
    
    if (_featureTable != nil) {
        [headerCell setDetailLabelOneText:[NSString stringWithFormat:@"feature layer in %@", _featureTable.database]];
        [headerCell setDetailLabelTwoText:[NSString stringWithFormat:@"%d features", _featureTable.count]];
        [headerCell setDetailLabelThreeText:@""];
        [_cellArray addObject:headerCell];
        
        MCFeatureLayerOperationsCell *featureButtonsCell = [self.tableView dequeueReusableCellWithIdentifier:@"featureButtons"];
        featureButtonsCell.delegate = self;
        [_cellArray addObject:featureButtonsCell];
        
        MCDescriptionCell *featureAddDescription = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
        [featureAddDescription setDescription:@"Long press the map to add points to this layer."];
        [featureAddDescription textAlignCenter];
        [_cellArray addObject:featureAddDescription];
        
        MCTitleCell *fieldsTitle = [self.tableView dequeueReusableCellWithIdentifier:@"title"];
        [fieldsTitle setLabelText:@"Fields"];
        [_cellArray addObject:fieldsTitle];
        
        MCButtonCell *addFieldsButton = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
        [addFieldsButton setButtonLabel:@"Add a field"];
        addFieldsButton.action = @"add-fields";
        addFieldsButton.delegate = self;
        [_cellArray addObject:addFieldsButton];
        
        if (self.columns.count == 2) {
            // TODO add empty state
        }
        
        for (GPKGUserColumn *column in self.columns) {
            if (![column.name isEqualToString:@"id"] && ![column.name isEqualToString:@"geom"]) {
                MCLayerCell *fieldCell = [self.tableView dequeueReusableCellWithIdentifier:@"field"];
                [fieldCell setName:column.name];
                [fieldCell activeIndicatorOff];
                
                if (column.dataType == GPKG_DT_TEXT) {
                    [fieldCell.layerTypeImage setImage:[UIImage imageNamed:@"text"]];
                    [fieldCell setDetails:@"Text"];
                } else if (column.dataType == GPKG_DT_INTEGER || column.dataType == GPKG_DT_REAL || column.dataType == GPKG_DT_DOUBLE || column.dataType == GPKG_DT_INT || column.dataType == GPKG_DT_FLOAT || column.dataType == GPKG_DT_SMALLINT || column.dataType == GPKG_DT_TINYINT || column.dataType == GPKG_DT_MEDIUMINT) {
                    [fieldCell.layerTypeImage setImage:[UIImage imageNamed:@"number"]];
                    [fieldCell setDetails:@"Number"];
                } else if (column.dataType == GPKG_DT_BOOLEAN) {
                    [fieldCell.layerTypeImage setImage:[UIImage imageNamed:@"boolean"]];
                    [fieldCell setDetails:@"Checkbox"];
                }
                
                [_cellArray addObject:fieldCell];
            }
        }
        
    } else if (_tileTable != nil) {
        MCTileLayerOperationsCell *tileButtonsCell = [self.tableView dequeueReusableCellWithIdentifier:@"tileButtons"];
        [headerCell setDetailLabelOneText: [NSString stringWithFormat:@"tile layer in %@", _tileTable.database]];
        [headerCell setDetailLabelTwoText: [NSString stringWithFormat:@"Zoom levels %d - %d",  _tileTable.minZoom, _tileTable.maxZoom]];
        [headerCell setDetailLabelThreeText:[NSString stringWithFormat:@"%d tiles", _tileTable.count]];
        tileButtonsCell.delegate = self;
        _cellArray = [[NSMutableArray alloc] initWithObjects:headerCell, tileButtonsCell, nil];
    }
    
    /*if (layerBoundingBox != nil) {
        GPKGBoundingBox *webMercatorBoundingBox = [layerBoundingBox transform:transformToWebMercator];
        SFPProjectionTransform *transform = [[SFPProjectionTransform alloc] initWithFromEpsg:PROJ_EPSG_WEB_MERCATOR andToEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
        layerBoundingBox = [webMercatorBoundingBox transform:transform];
        // [headerCell.mapView setRegion:layerBoundingBox.getCoordinateRegion]; // TODO sort this out for the new map
    }*/
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void) update {
    [self initCellArray];
    [self.tableView reloadData];
}


#pragma mark - Table view data source and delegate methods
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cellArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [_cellArray objectAtIndex:indexPath.row];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}


- (void) renameLayer {
    NSLog(@"Renaming Layer");
    
    UIAlertController *renameAlert = [UIAlertController alertControllerWithTitle:@"Rename Layer" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [renameAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        [textField setText:self.table.name];
    }];
    
    UIAlertAction *confirmRename = [UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"New name is: %@", renameAlert.textFields[0].text);
        
        NSString * newName = renameAlert.textFields[0].text;
        
        bool validName = newName != nil && [newName length] > 0 && ![newName isEqualToString:self.table.name];
        if(validName){
            @try {
                NSString *originalName = self.table.name;
                
                if([self.delegate renameLayer:newName]){
                    [self.table setName:newName];
                    [self initCellArray];
                    [self.tableView reloadData];
                }else{
                    [MCUtils showMessageWithDelegate:self
                                               andTitle:[MCProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_RENAME_LABEL]
                                             andMessage:[NSString stringWithFormat:@"Rename from %@ to %@ was not successful", originalName, newName]];
                }
            }
            @catch (NSException *exception) {
                [MCUtils showMessageWithDelegate:self
                                           andTitle:[NSString stringWithFormat:@"Rename %@ to %@", @"OLDNAME", newName]
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


- (void) deleteLayer {
    NSLog(@"Deleting layer");
    
    UIAlertController *deleteAlert = [UIAlertController alertControllerWithTitle:@"Delete" message:@"Do you wanbt to delete this layer? This action can not be undone." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirmDelete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self.delegate deleteLayer];
        [self dismissViewControllerAnimated:YES completion:nil];
    }];
    
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [deleteAlert dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [deleteAlert addAction:confirmDelete];
    [deleteAlert addAction:cancel];
    
    [self presentViewController:deleteAlert animated:YES completion:nil];
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[_cellArray objectAtIndex:indexPath.row] isKindOfClass:[MCLayerCell class]]) {
        return YES;
    } else {
        return NO;
    }
}


- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        MCLayerCell *cell = [self.cellArray objectAtIndex:indexPath.row];
        GPKGUserColumn *columnToDelete = nil;
        
        for (GPKGUserColumn *column in self.columns) {
            if ([cell.layerNameLabel.text isEqualToString:column.name]) {
                columnToDelete = column;
            }
        }
        
        UIAlertController *deleteAlert = [UIAlertController alertControllerWithTitle:@"Delete" message:@"Do you want to delete this field? Data saved in this field will be lost for all points in this layer. This action can not be undone." preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *confirmDelete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            @try {
                [self.delegate deleteColumn:columnToDelete];
            }
            @catch (NSException *exception) {
                [MCUtils showMessageWithDelegate:self
                                           andTitle:[NSString stringWithFormat:@"Delete failed"]
                                         andMessage:[NSString stringWithFormat:@"%@", [exception description]]];
            }
        }];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [deleteAlert dismissViewControllerAnimated:YES completion:nil];
        }];
        
        [deleteAlert addAction:confirmDelete];
        [deleteAlert addAction:cancel];
        [self presentViewController:deleteAlert animated:YES completion:nil];
        
        completionHandler(YES);
    }];
    
    
    UIContextualAction *renameAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Rename" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        MCLayerCell *cell = [self.cellArray objectAtIndex:indexPath.row];
        GPKGUserColumn *columnToRename = nil;
        
        for (GPKGUserColumn *column in self.columns) {
            if ([cell.layerNameLabel.text isEqualToString:column.name]) {
                columnToRename = column;
            }
        }
        
        UIAlertController *renameAlert = [UIAlertController alertControllerWithTitle:@"Rename" message:@"" preferredStyle:UIAlertControllerStyleAlert];
        [renameAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
            [textField setText:cell.layerNameLabel.text];
        }];
        
        UIAlertAction *confirmRename = [UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            NSLog(@"New name is: %@", renameAlert.textFields[0].text);
            NSString * newName = renameAlert.textFields[0].text;
            
            if(newName != nil && [newName length] > 0){
                @try {
                    [self.delegate renameColumn:columnToRename name:newName];
                }
                @catch (NSException *exception) {
                    [MCUtils showMessageWithDelegate:self
                                               andTitle:[NSString stringWithFormat:@"Rename failed"]
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
        
        completionHandler(YES);
    }];
    
    
    
    deleteAction.backgroundColor = [UIColor redColor];
    renameAction.backgroundColor = [UIColor orangeColor];
    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:@[deleteAction, renameAction]];
    configuration.performsFirstActionWithFullSwipe = YES;
    return configuration;
}



#pragma mark - MCFeatureLayerOperationsCellDelegate methods
// TODO pass these up to be done in the repository
- (void) renameFeatureLayer {
    NSLog(@"MCLayerOperationsDelegate editLayer");
    [self renameLayer];
}


- (void) indexFeatures {
    NSLog(@"MCLayerOperationsDelegate indexLayer");
    //[_delegate indexLayer];
}


- (void) createTiles {
    NSLog(@"MCLayerOperationsDelegate createTiles");
    //[_delegate createTiles];
}


- (void) createOverlay {
    NSLog(@"MCLayerOperationsDelegate createOverlay");
    //[_delegate createOverlay];
}


- (void) deleteFeatureLayer {
    NSLog(@"MCFeatureButtonsCellDelegate deleteLayer %@", _table.name);
    [self deleteLayer];
    
}


#pragma mark - MCButtonCellDelegate methods
- (void)performButtonAction:(NSString *)action {
    if ([action isEqualToString:@"add-fields"]) {
        
        NSLog(@"show create fields view");
        [_delegate showFieldCreationView];
    }
}


#pragma mark - MCTileButtonsDelegate methods
- (void) renameTileLayer {
    NSLog(@"MCTileButtonsDelegate renameLayer");
    [self renameLayer];
}


- (void) showScalingOptions {
    NSLog(@"MCTileButtonsDelegate showScalingOptions");
    //[_delegate showTileScalingOptions];
}


- (void) deleteTileLayer {
    NSLog(@"MCTileButtonsDelegate deleteTileLayer");
    [self deleteLayer];
}


- (void)closeDrawer {
    [self.drawerViewDelegate popDrawer];
    [self.delegate layerViewCompletionHandler];
}


- (void) drawerWasCollapsed {
    [super drawerWasCollapsed];
    [self.tableView setScrollEnabled:NO];
}


- (void) drawerWasMadeFull {
    [super drawerWasMadeFull];
    [self.tableView setScrollEnabled:YES];
}


- (void) becameTopDrawer {
    [self.delegate setSelectedLayerName];
}


- (BOOL)gestureIsInConflict:(UIPanGestureRecognizer *) recognizer {
    CGPoint point = [recognizer locationInView:self.view];
    
    if (CGRectContainsPoint(self.tableView.frame, point)) {
        return true;
    }
    
    return false;
}


// Override this method to make the drawer and the scrollview play nice
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.haveScrolled) {
        [self rollUpPanGesture:scrollView.panGestureRecognizer withScrollView:scrollView];
    }
}


// If the table view is scrolling rollup the gesture to the drawer and handle accordingly.
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.haveScrolled = YES;
    
    if (!self.isFullView) {
        scrollView.scrollEnabled = NO;
        scrollView.scrollEnabled = YES;
    } else {
        scrollView.scrollEnabled = YES;
    }
}


@end
