//
//  MCSettingsViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/5/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCSettingsViewController.h"

NSString * const SHOW_NOTICE = @"showNotice";

@interface MCSettingsViewController ()
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) MCSegmentedControlCell *baseMapSelector;
@property (nonatomic, strong) MCFieldWithTitleCell *maxFeaturesCell;
@end

@implementation MCSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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


- (void) closeDrawer {
    [super closeDrawer];
    [self.drawerViewDelegate popDrawer];
}


- (void)initCellArray {
    _cellArray = [[NSMutableArray alloc] init];
    
    MCTitleCell *titleCell = [_tableView dequeueReusableCellWithIdentifier:@"title"];
    titleCell.label.text = @"Settings";
    [_cellArray addObject:titleCell];
    
    _baseMapSelector = [_tableView dequeueReusableCellWithIdentifier:@"segmentedControl"];
    _baseMapSelector.label.text = @"Base Map Type";
    _baseMapSelector.delegate = self;
    NSArray *maps = [[NSArray alloc] initWithObjects:@"Standard", @"Satellite", @"Hybrid", nil];
    [_baseMapSelector setItems:maps];
    [_cellArray addObject:_baseMapSelector];
    
    _maxFeaturesCell = [_tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _maxFeaturesCell.title.text = @"Maximum number of features";
    [_cellArray addObject:_maxFeaturesCell];
    
    MCButtonCell *showNoticesButtonCell = [self.tableView dequeueReusableCellWithIdentifier:@"buttonCell"];
    [showNoticesButtonCell.button setTitle:@"About MapCache" forState:UIControlStateNormal];
    showNoticesButtonCell.action = SHOW_NOTICE;
    showNoticesButtonCell.delegate = self;
    [_cellArray addObject:showNoticesButtonCell];

}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCSectionTitleCell" bundle:nil] forCellReuseIdentifier:@"sectionTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCSegmentedControlCell" bundle:nil] forCellReuseIdentifier:@"segmentedControl"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCFieldWithTitleCell" bundle:nil] forCellReuseIdentifier:@"fieldWithTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCButtonCell" bundle:nil] forCellReuseIdentifier:@"buttonCell"];
}


#pragma mark - TableView delegate methods
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [_cellArray objectAtIndex:indexPath.row];
}
    

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cellArray count];
}


#pragma mark - MCSegmentedControlDelegate method
- (void)selectionChanged:(NSString *)selection {
    [_settingsDelegate setMapType:selection];
}


#pragma mark - ButtonCell delegate
- (void)performButtonAction:(NSString *)action {
    if ([action isEqualToString:SHOW_NOTICE]) {
        [self.noticeAndAttributeDelegate showNoticeAndAttributeView];
    }
}


@end
