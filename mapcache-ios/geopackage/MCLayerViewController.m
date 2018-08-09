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
@property (strong, nonatomic) GPKGFeatureDao *featureDao;
@property (strong, nonatomic) GPKGTileDao *tileDao;
@property (strong, nonatomic) GPKGGeoPackageManager *manager;
@end

@implementation MCLayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([_layerDao isKindOfClass:GPKGFeatureDao.class]) {
        _featureDao = (GPKGFeatureDao *) _layerDao;
        _tileDao = nil;
    } else if ([_layerDao isKindOfClass:GPKGTileDao.class]) {
        _tileDao = (GPKGTileDao *) _layerDao;
        _featureDao = nil;
    }
    
    [self registerCellTypes];
    [self initCellArray];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsMultipleSelection = NO;
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    UIEdgeInsets tabBarInsets = UIEdgeInsetsMake(0, 0, self.tabBarController.tabBar.frame.size.height, 0);
    self.tableView.contentInset = tabBarInsets;
    self.tableView.scrollIndicatorInsets = tabBarInsets;
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCHeaderCellDisplay" bundle:nil] forCellReuseIdentifier:@"header"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCFeatureLayerOperationsCell" bundle:nil] forCellReuseIdentifier:@"featureButtons"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTileLayerOperationsCell" bundle:nil] forCellReuseIdentifier:@"tileButtons"];
}


- (void) initCellArray {
    if ([_cellArray count] > 0) {
        [_cellArray removeAllObjects];
    }
    
    MCHeaderCell *headerCell = [self.tableView dequeueReusableCellWithIdentifier:@"header"];
    headerCell.nameLabel.text = _layerDao.tableName;
    _cellArray = [[NSMutableArray alloc] initWithObjects:headerCell, nil];
    
    if (_featureDao != nil) {
        MCFeatureLayerOperationsCell *featureButtonsCell = [self.tableView dequeueReusableCellWithIdentifier:@"featureButtons"];
        featureButtonsCell.delegate = self;
        [_cellArray addObject:featureButtonsCell];
    } else if (_tileDao != nil) {
        MCTileLayerOperationsCell *tileButtonsCell = [self.tableView dequeueReusableCellWithIdentifier:@"tileButtons"];
        tileButtonsCell.delegate = self;
        [_cellArray addObject:tileButtonsCell];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cellArray count];
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [_cellArray objectAtIndex:indexPath.row];
}


- (void) renameLayer:(GPKGUserDao *) dao {
    NSLog(@"Renaming Layer");
    
    UIAlertController *renameAlert = [UIAlertController alertControllerWithTitle:@"Rename Layer" message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [renameAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = dao.tableName;
    }];
    
    UIAlertAction *confirmRename = [UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"New name is: %@", renameAlert.textFields[0].text);
        
        NSString * newName = renameAlert.textFields[0].text;
        
        if(newName != nil && [newName length] > 0 && ![newName isEqualToString:dao.tableName]){
            @try {
                if(newName != nil && [newName length] > 0 && ![newName isEqualToString:dao.tableName]){
                    //self.database.name = newName;
                    [self initCellArray];
                    [self.tableView reloadData];
                }else{
                    [GPKGSUtils showMessageWithDelegate:self
                                               andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_RENAME_LABEL]
                                             andMessage:[NSString stringWithFormat:@"Rename from %@ to %@ was not successful", @"OLDNAME", newName]];
                }
            }
            @catch (NSException *exception) {
                [GPKGSUtils showMessageWithDelegate:self
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


#pragma mark - MCFeatureLayerOperationsCellDelegate methods
- (void) renameFeatureLayer {
    NSLog(@"MCLayerOperationsDelegate editLayer");
    [self renameLayer: _featureDao];
}


- (void) indexFeatures {
    NSLog(@"MCLayerOperationsDelegate indexLayer");
    [_delegate indexLayer];
}


- (void) createTiles {
    NSLog(@"MCLayerOperationsDelegate createTiles");
    [_delegate createTiles];
}


- (void) createOverlay {
    NSLog(@"MCLayerOperationsDelegate createOverlay");
    [_delegate createOverlay];
}


- (void) deleteFeatureLayer {
    NSLog(@"MCFeatureButtonsCellDelegate deleteLayer %@", _featureDao.tableName);
    [self deleteLayer];
    
}


#pragma mark - MCTileButtonsDelegate methods
- (void) renameTileLayer {
    NSLog(@"MCTileButtonsDelegate renameLayer");
    [self renameLayer: _tileDao];
}


- (void) showScalingOptions {
    NSLog(@"MCTileButtonsDelegate showScalingOptions");
    [_delegate showTileScalingOptions];
}


- (void) deleteTileLayer {
    NSLog(@"MCTileButtonsDelegate deleteTileLayer");
    [self deleteLayer];
}


@end
