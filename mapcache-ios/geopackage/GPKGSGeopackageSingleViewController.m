//
//  GPKGSGeopackageSingleViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 10/31/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "GPKGSGeopackageSingleViewController.h"

@interface GPKGSGeopackageSingleViewController ()
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *cellArray;
@property (strong, nonatomic) GPKGGeoPackageManager *manager;
@property (strong, nonatomic) UIDocumentInteractionController *shareDocumentController;
@end

@implementation GPKGSGeopackageSingleViewController

- (void) viewDidLoad {
    [super viewDidLoad];
    [self registerCellTypes];
    [self initCellArray];
    
    self.manager = [GPKGGeoPackageFactory getManager];
    _tableView.estimatedRowHeight = 45.0;
    _tableView.rowHeight = UITableViewAutomaticDimension;
}


- (void) didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}


- (void) initCellArray {
    if ([_cellArray count] > 0) {
        [_cellArray removeAllObjects];
    }
    
    GPKGGeoPackage * geoPackage = [_manager open:_database.name];
    
    GPKGSHeaderCellTableViewCell *headerCell = [_tableView dequeueReusableCellWithIdentifier:@"header"];
    headerCell.nameLabel.text = _database.name;
    
    NSLog(@"GeoPackage Size %@", [self.manager readableSize:_database.name]);
    headerCell.sizeLabel.text = [self.manager readableSize:_database.name]; // TODO look into threading this 
    
    NSInteger tileCount = [_database getTileCount];
    NSString *tileText = tileCount == 1 ? @"tile" : @"tiles";
    headerCell.tileCountLabel.text = [NSString stringWithFormat:@"%ld %@", tileCount, tileText];
    
    NSInteger featureCount = [_database getFeatureCount];
    NSString *featureText = featureCount == 1 ? @"feature" : @"features";
    headerCell.featureCountLabel.text = [NSString stringWithFormat:@"%ld %@", featureCount, featureText];
    
    headerCell.delegate = self;
    
    GPKGSSectionTitleCell *titleCell = [_tableView dequeueReusableCellWithIdentifier:@"sectionTitle"];
    titleCell.sectionTitleLabel.text = @"Layers";
    
    _cellArray = [[NSMutableArray alloc] initWithObjects: headerCell, titleCell, nil];
    
    NSArray *tables = [_database getTables];
    
    for (GPKGSTable *table in tables) {
        GPKGSLayerCell *layerCell = [_tableView dequeueReusableCellWithIdentifier:@"layerCell"];
        NSString *typeImageName = @"";
        
        if ([table isMemberOfClass:[GPKGSFeatureTable class]]) {
            typeImageName = [GPKGSProperties getValueOfProperty:GPKGS_PROP_ICON_GEOMETRY];
        } else if ([table isMemberOfClass:[GPKGSTileTable class]]) {
            typeImageName = [GPKGSProperties getValueOfProperty:GPKGS_PROP_ICON_TILES];
        }
        
        layerCell.layerNameLabel.text = table.name;
        [layerCell.layerTypeImage setImage:[UIImage imageNamed:typeImageName]];
        [_cellArray addObject:layerCell];
    }
    
    GPKGSButtonCell *newLayerButtonCell = [_tableView dequeueReusableCellWithIdentifier:@"buttonCell"];
    [newLayerButtonCell.button setTitle:@"New Layer" forState:UIControlStateNormal];
    newLayerButtonCell.action = GPKGS_ACTION_NEW_LAYER;
    newLayerButtonCell.delegate = self;
    [_cellArray addObject:newLayerButtonCell];
    
    // add title cell for reference systems
    // loop over geospatial reference systems create cells, push to array
}


- (void) registerCellTypes {
    [_tableView registerNib:[UINib nibWithNibName:@"GPKGSHeaderCellDisplay" bundle:nil] forCellReuseIdentifier:@"header"];
    [_tableView registerNib:[UINib nibWithNibName:@"GPKGSSectionTitleCell" bundle:nil] forCellReuseIdentifier:@"sectionTitle"];
    [_tableView registerNib:[UINib nibWithNibName:@"GPKGSLayerCell" bundle:nil] forCellReuseIdentifier:@"layerCell"];
    [_tableView registerNib:[UINib nibWithNibName:@"GPKGSButtonCell" bundle:nil] forCellReuseIdentifier:@"buttonCell"];
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if (self.isMovingFromParentViewController) {
        [_delegate callCompletionHandler];
    }
}


#pragma mark - TableView delegate methods
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [_cellArray objectAtIndex:indexPath.row];
}


- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cellArray count];
}


#pragma mark - Cell delegate methods
-(void) deleteGeoPackage {
    NSLog(@"Deleting GeoPackage...");
    
    UIAlertController *deleteAlert = [UIAlertController alertControllerWithTitle:@"Delete" message:@"Do you want to delete this GeoPackage? This action can not be undone." preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *confirmDelete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [_delegate deleteGeoPackage];
        [self dismissViewControllerAnimated:YES completion:nil];
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
        textField.text = _database.name;
    }];
    
    UIAlertAction *confirmRename = [UIAlertAction actionWithTitle:@"Rename" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        NSLog(@"New name is: %@", renameAlert.textFields[0].text);
        
        NSString * newName = renameAlert.textFields[0].text;
        
        if(newName != nil && [newName length] > 0 && ![newName isEqualToString:_database.name]){
            @try {
                if([_manager rename:_database.name to:newName]){
                    _database.name = newName;
                    [self initCellArray];
                    [_tableView reloadData];
                }else{
                    [GPKGSUtils showMessageWithDelegate:self
                                               andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_GEOPACKAGE_RENAME_LABEL]
                                             andMessage:[NSString stringWithFormat:@"Rename from %@ to %@ was not successful", _database.name, newName]];
                }
            }
            @catch (NSException *exception) {
                [GPKGSUtils showMessageWithDelegate:self
                                           andTitle:[NSString stringWithFormat:@"Rename %@ to %@", _database.name, newName]
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
        textField.text = [NSString stringWithFormat:@"%@_copy", _database.name];
    }];
    
    UIAlertAction *confirmCopy = [UIAlertAction actionWithTitle:@"Copy" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString * newName = [copyAlert.textFields[0] text];
        NSString *database = _database.name;
        if(newName != nil && [newName length] > 0 && ![newName isEqualToString:database]){
            @try {
                if([self.manager copy:database to:newName]){
                    NSLog(@"Copy Successful");
                    UIAlertController *confirmation = [UIAlertController alertControllerWithTitle:@"Success" message:@"Copy created." preferredStyle:UIAlertControllerStyleAlert];
                    [self presentViewController:confirmation animated:YES completion:nil];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [confirmation dismissViewControllerAnimated:YES completion:nil];
                        [_delegate copyGeoPackage];
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


- (void) getInfo {
    // TODO add code to show info sheet
}


- (void)performButtonAction:(NSString *) action {
    NSLog(@"Button pressed, checking action...");
    
    if ([action isEqualToString:GPKGS_ACTION_NEW_LAYER]) {
        NSLog(@"Button pressed, handling action %@", action);
        [_delegate newLayer];
    }
}


@end
