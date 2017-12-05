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
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) UIDocumentInteractionController *shareDocumentController;
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
    GPKGSHeaderCellTableViewCell *headerCell = [_tableView dequeueReusableCellWithIdentifier:@"header"];
    headerCell.nameLabel.text = _database.name;
    
    NSLog(@"GeoPackage Size %@", [self.manager readableSize:_database.name]);
    headerCell.sizeLabel.text = [self.manager readableSize:_database.name];
    
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
    [_delegate deleteGeoPackage];
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


- (void)performButtonAction:(NSString *) action {
    NSLog(@"Button pressed, checking action...");
    
    if ([action isEqualToString:GPKGS_ACTION_NEW_LAYER]) {
        NSLog(@"Button pressed, handling action %@", action);
        [_delegate newLayer];
    }
}


@end
