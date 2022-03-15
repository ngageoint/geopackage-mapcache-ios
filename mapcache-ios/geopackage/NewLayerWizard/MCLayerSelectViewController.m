//
//  MCLayerSelectViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 3/30/21.
//  Copyright © 2021 NGA. All rights reserved.
//

#import "MCLayerSelectViewController.h"
#import "mapcache_ios-Swift.h"

@interface MCLayerSelectViewController ()
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) UITableView *tableView;

@end


@implementation MCLayerSelectViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] init];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 390.0;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    [self registerCellTypes];
    [self initCellArray];
    [self addAndConstrainSubview:self.tableView];
    [self addDragHandle];
    [self addCloseButton];
}


- (void) closeDrawer {
   [super closeDrawer];
   [self.drawerViewDelegate popDrawerAndHide];
}


- (void) initCellArray {
    _cellArray = [[NSMutableArray alloc] init];
    
    MCTitleCell *titleCell = [_tableView dequeueReusableCellWithIdentifier:@"title"];
    [titleCell setLabelText:@"Choose your layer"];
    [_cellArray addObject:titleCell];
    
    for (MCLayer *layer in self.tileServer.layers) {
        if (![layer.name isEqualToString:@""]) {
            MCLayerCell *layerCell = [_tableView dequeueReusableCellWithIdentifier:@"layerCell"];
            [layerCell setContentsWithLayer:layer tileServer:self.tileServer];
            [_cellArray addObject:layerCell];
        }
    }
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCSectionTitleCell" bundle:nil] forCellReuseIdentifier:@"sectionTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCButtonCell" bundle:nil] forCellReuseIdentifier:@"buttonCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCLayerCell" bundle:nil] forCellReuseIdentifier:@"layerCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTileServerCell" bundle:nil] forCellReuseIdentifier:@"tileServerCell"];
}


#pragma mark - TableView delegate methods
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [_cellArray objectAtIndex: indexPath.row];
}
    

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _cellArray.count;
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if ([[_cellArray objectAtIndex:indexPath.row] isKindOfClass:MCLayerCell.class]) {
        MCLayerCell *layerCell = [_cellArray objectAtIndex:indexPath.row];
        NSInteger index = (NSInteger)[self.tileServer.layers indexOfObject:layerCell.mapLayer];
        [self.layerSelectDelegate didSelectLayer:index];
        [self.drawerViewDelegate popDrawerAndHide];
    }
    
    // call delegate
    // pop drawer
}

@end
