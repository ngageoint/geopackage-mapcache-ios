//
//  MCDrawingStatusViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/20/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "MCDrawingStatusViewController.h"

@interface MCDrawingStatusViewController ()
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) MCDescriptionCell *statusCell;
@property (nonatomic, strong) MCDualButtonCell *buttonsCell;
@property (nonatomic, strong) MCTable *selectedTable;
@end

@implementation MCDrawingStatusViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect bounds = self.view.bounds;
    CGRect insetBounds = CGRectMake(bounds.origin.x, bounds.origin.y + 6, bounds.size.width, bounds.size.height);
    self.tableView = [[UITableView alloc] initWithFrame: insetBounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    //self.tableView.estimatedRowHeight = 390.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    [self registerCellTypes];
    [self initCellArray];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    
    [self.view addSubview:self.tableView];
    [self.tableView setScrollEnabled:NO];
}


- (void)registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDualButtonCell" bundle:nil] forCellReuseIdentifier:@"buttons"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCGeoPackageCell" bundle:nil] forCellReuseIdentifier:@"geopackage"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCLayerCell" bundle:nil] forCellReuseIdentifier:@"layer"];
}


- (void)initCellArray {
    _cellArray = [[NSMutableArray alloc] init];
    
    _statusCell = [_tableView dequeueReusableCellWithIdentifier:@"description"];
    [_statusCell textAlignCenter];
    [_statusCell setDescription:@"1 new point"];
    
    _buttonsCell = [_tableView dequeueReusableCellWithIdentifier:@"buttons"];
    _buttonsCell.dualButtonDelegate = self;
    [_buttonsCell setLeftButtonLabel:@"Cancel"];
    [_buttonsCell setLeftButtonAction:@"cancel"];
    [_buttonsCell setRightButtonLabel:@"Continue"];
    [_buttonsCell setRightButtonAction:@"show-select"];
    
    [_cellArray addObject:_statusCell];
    [_cellArray addObject:_buttonsCell];
}


- (void)refreshViewWithNewGeoPackageList:(NSArray *)databases {
    [_tableView reloadData];
    _databases = databases;
    [self showGeoPackageSelectMode];
}


- (void)showGeoPackageSelectMode {
    NSMutableArray *switchModeCells = [[NSMutableArray alloc] init];
    
    _buttonsCell = [_tableView dequeueReusableCellWithIdentifier:@"buttons"];
    _buttonsCell.dualButtonDelegate = self;
    [_buttonsCell setLeftButtonLabel:@"Cancel"];
    [_buttonsCell setLeftButtonAction:@"cancel"];
    [_buttonsCell setRightButtonLabel:@"New GeoPacakge"];
    [_buttonsCell setRightButtonAction:@"new-geopackage"];
    [switchModeCells addObject:_buttonsCell];
    
    MCDescriptionCell *chooseGeoPackageHelp = [_tableView dequeueReusableCellWithIdentifier:@"description"];
    [chooseGeoPackageHelp setDescription:@"To save your new point, either create a new GeoPackage or select one from below."];
    [switchModeCells addObject:chooseGeoPackageHelp];
    
    for (MCDatabase *database in _databases) {
        MCGeoPackageCell *geoPackageCell = [_tableView dequeueReusableCellWithIdentifier:@"geopackage"];
        [geoPackageCell setContentWithDatabase:database];
        [geoPackageCell activeLayersIndicatorOff];
        [switchModeCells addObject:geoPackageCell];
    }
    
    [self makeFullView];
    _cellArray = switchModeCells;
    
    [_tableView reloadData];
    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView setScrollEnabled:YES];
}


- (void)updateStatusLabelWithString:(NSString *) string {
    [_statusCell setDescription:string];
    
}


- (void)showLayerSelectionMode {
    NSMutableArray *layerSelectionModeCells = [[NSMutableArray alloc] init];
    
    _buttonsCell = [_tableView dequeueReusableCellWithIdentifier:@"buttons"];
    _buttonsCell.dualButtonDelegate = self;
    [_buttonsCell setLeftButtonLabel:@"Cancel"];
    [_buttonsCell setLeftButtonAction:@"cancel"];
    [_buttonsCell setRightButtonLabel:@"New Layer"];
    [_buttonsCell setRightButtonAction:@"new-layer"];
    [layerSelectionModeCells addObject:_buttonsCell];
    
    MCGeoPackageCell *geoPackageCell = [_tableView dequeueReusableCellWithIdentifier:@"geopackage"];
    [geoPackageCell setContentWithDatabase:_selectedGeoPackage];
    [geoPackageCell activeLayersIndicatorOff];
    [layerSelectionModeCells addObject:geoPackageCell];

    MCDescriptionCell *chooselayerHelp = [_tableView dequeueReusableCellWithIdentifier:@"description"];
    [chooselayerHelp setDescription:@"Create a new layer or select one from below."];
    [layerSelectionModeCells addObject:chooselayerHelp];
    
    for (MCTable *table in [_selectedGeoPackage getFeatures]) {
        MCLayerCell *layerCell = [_tableView dequeueReusableCellWithIdentifier:@"layer"];
        [layerCell setContentsWithTable:table];
        [layerCell activeIndicatorOff];
        [layerSelectionModeCells addObject:layerCell];
    }
    
    _cellArray = layerSelectionModeCells;
    [_tableView reloadData];
    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [self.tableView setScrollEnabled:YES];
}


- (void)showSaveMode {
    NSMutableArray *saveModeCells = [[NSMutableArray alloc] init];
    
    MCDescriptionCell *saveDescription = [_tableView dequeueReusableCellWithIdentifier:@"description"];
    [saveDescription setDescription:@"Tap below to save your features."];
    [saveModeCells addObject:saveDescription];
    
    MCGeoPackageCell *geoPackageCell = [_tableView dequeueReusableCellWithIdentifier:@"geopackage"];
    [geoPackageCell setContentWithDatabase:_selectedGeoPackage];
    [geoPackageCell activeLayersIndicatorOff];
    [saveModeCells addObject:geoPackageCell];
    
    MCLayerCell *layerCell = [_tableView dequeueReusableCellWithIdentifier:@"layer"];
    [layerCell setContentsWithTable:_selectedTable];
    [layerCell activeIndicatorOff];
    [saveModeCells addObject:layerCell];
    
    _buttonsCell = [_tableView dequeueReusableCellWithIdentifier:@"buttons"];
    _buttonsCell.dualButtonDelegate = self;
    [_buttonsCell setLeftButtonLabel:@"Discard"];
    [_buttonsCell setLeftButtonAction:@"cancel"];
    [_buttonsCell setRightButtonLabel:@"Save"];
    [_buttonsCell setRightButtonAction:@"save"];
    [saveModeCells addObject:_buttonsCell];
    
    _cellArray = saveModeCells;
    [_tableView reloadData];
    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}


#pragma mark - UITableView datasource and delegate methods
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [_cellArray objectAtIndex:indexPath.row];
}


- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cellArray count];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSObject *cellObject = [_cellArray objectAtIndex:indexPath.row];
    
    if ([cellObject isKindOfClass:[MCGeoPackageCell class]]) {
        _selectedGeoPackage = ((MCGeoPackageCell *)cellObject).database;
        [self.drawingStatusDelegate didSelectGeoPackage:_selectedGeoPackage.name];
        [self showLayerSelectionMode];
    } else if ([cellObject isKindOfClass:[MCLayerCell class]]) {
        _selectedTable = ((MCLayerCell *)cellObject).table;
        [self.drawingStatusDelegate didSelectLayer:_selectedTable.name];
    }
        
}


#pragma mark - MCDualButtonCellDelegate
- (void) performDualButtonAction:(NSString *)action {
    if ([action isEqualToString:@"show-select"]) {
        NSLog(@"Continue tapped");
        [self showGeoPackageSelectMode];
    } else if ([action isEqualToString:@"new-geopackage"]) {
        NSLog(@"Show new GeoPackage view.");
        [self.drawingStatusDelegate showNewGeoPacakgeView];
    } else if ([action isEqualToString:@"new-layer"]) {
        NSLog(@"Show new layer view.");
        [self.drawingStatusDelegate showNewLayerViewWithDatabase:_selectedGeoPackage];
    } else if ([action isEqualToString:@"save"]) {
        BOOL pointsSaved = [self.drawingStatusDelegate savePointsToDatabase: _selectedGeoPackage andTable:_selectedTable];
        if (pointsSaved) {
            [self.drawerViewDelegate popDrawer];
        }
    } else {
        NSLog(@"Cancel tapped");
        [self.drawingStatusDelegate cancelDrawingFeatures];
        [self.drawerViewDelegate popDrawer];
    }
}


@end
