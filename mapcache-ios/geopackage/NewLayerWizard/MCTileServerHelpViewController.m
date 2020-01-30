//
//  MCTileServerHelpViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/7/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "MCTileServerHelpViewController.h"

@interface MCTileServerHelpViewController ()
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation MCTileServerHelpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] init];
    CGRect bounds = self.view.bounds;
    CGRect insetBounds = CGRectMake(bounds.origin.x, bounds.origin.y + 32, bounds.size.width, bounds.size.height - 20);
    self.tableView = [[UITableView alloc] initWithFrame: insetBounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 390.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    
    [self registerCellTypes];
    [self initCellArray];
    
    UIEdgeInsets tabBarInsets = UIEdgeInsetsMake(0, 0, self.tabBarController.tabBar.frame.size.height, 0);
    self.tableView.contentInset = tabBarInsets;
    self.tableView.scrollIndicatorInsets = tabBarInsets;
    [self.view addSubview:self.tableView];
    [self addDragHandle];
    [self addCloseButton];
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
}


- (void) initCellArray {
    _cellArray = [[NSMutableArray alloc] init];
    
    MCTitleCell *title = [self.tableView dequeueReusableCellWithIdentifier:@"title"];
    title.label.text = @"Formatting Map Tile URLs";
    
    MCDescriptionCell *xyzDescription = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    xyzDescription.descriptionLabel.text = @"For XYZ tile servers, make sure the URL is formatted with the template on the end:";
    
    MCDescriptionCell *xyzExample = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    xyzExample.descriptionLabel.text = @"https://yourtileserver.com/{z}/{x}/{y}.png";
    
    MCDescriptionCell *wmsDescription = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    wmsDescription.descriptionLabel.text = @"For WMS tile servers, make sure the URL is formatted with the bounding box coordinates as a template in the query parameters:";
    
    MCDescriptionCell *wmsExample = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    wmsExample.descriptionLabel.text = @"&bbox={minLon},{minLat},{maxLon},{maxLat}";
    
    MCButtonCell *button = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [button.button setTitle:@"Continue" forState:UIControlStateNormal];
    button.action = @"Continue";
    button.delegate = self;
    
    [_cellArray addObject:title];
    [_cellArray addObject:xyzDescription];
    [_cellArray addObject:xyzExample];
    [_cellArray addObject:wmsDescription];
    [_cellArray addObject:wmsExample];
    [_cellArray addObject:button];
}


#pragma mark - UITableViewDelegate methods
-(UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [_cellArray objectAtIndex:indexPath.row];
}


- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cellArray count];
}


#pragma mark - GPKGSButtonCellDelegate methods
- (void) performButtonAction:(NSString *)action {
    if ([action isEqualToString:@"Continue"]) {
        [self closeDrawer];
    }
}


#pragma mark - NGADrawerView methods
- (void) closeDrawer {
    [self.drawerViewDelegate popDrawer];
}


@end
