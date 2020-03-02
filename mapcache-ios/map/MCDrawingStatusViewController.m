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
@end

@implementation MCDrawingStatusViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect bounds = self.view.bounds;
    CGRect insetBounds = CGRectMake(bounds.origin.x, bounds.origin.y - 16, bounds.size.width, bounds.size.height);
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
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self.view addSubview:self.tableView];
    [self.tableView setScrollEnabled:NO];
}


- (void)registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDualButtonCell" bundle:nil] forCellReuseIdentifier:@"buttons"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCGeoPackageCell" bundle:nil] forCellReuseIdentifier:@"geopackage"];
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
    [_buttonsCell setRightButtonLabel:@"Save"];
    [_buttonsCell setRightButtonAction:@"save"];
    
    [_cellArray addObject:_statusCell];
    [_cellArray addObject:_buttonsCell];
}


- (void)switchToSaveLocationMode {
    NSMutableArray *switchModeCells = [[NSMutableArray alloc] init];
    [switchModeCells addObject:[_cellArray objectAtIndex:0]];
    
    _buttonsCell = [_tableView dequeueReusableCellWithIdentifier:@"buttons"];
    _buttonsCell.dualButtonDelegate = self;
    [_buttonsCell setLeftButtonLabel:@"Cancel"];
    [_buttonsCell setLeftButtonAction:@"cancel"];
    [_buttonsCell setRightButtonLabel:@"Save"];
    [_buttonsCell setRightButtonAction:@"save"];
    [switchModeCells addObject:_buttonsCell];
    
    for (NSString *databaseName in self.databases) {
        MCGeoPackageCell *geoPackageCell = [_tableView dequeueReusableCellWithIdentifier:@"geopackage"];
        geoPackageCell.geoPackageNameLabel.text = databaseName;
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


#pragma mark - UITableView datasource and delegate methods
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [_cellArray objectAtIndex:indexPath.row];
}


- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cellArray count];
}


#pragma mark - MCDualButtonCellDelegate
- (void) performDualButtonAction:(NSString *)action {
    if ([action isEqualToString:@"save"]) {
        NSLog(@"Save tapped");
        [self.drawingStatusDelegate showSaveLocationView];
        [self switchToSaveLocationMode];
    } else {
        NSLog(@"Cancel tapped");
        [self.drawingStatusDelegate cancelDrawingFeatures];
        [self.drawerViewDelegate popDrawer];
        // TODO call end delegate method
    }
}


@end
