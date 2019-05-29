//
//  MCBoundingBoxDetailsViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 12/9/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCBoundingBoxDetailsViewController.h"

@interface MCBoundingBoxDetailsViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) GPKGBoundingBox *boundingBox;
@property (nonatomic, strong) NSString* startBoundingBoxCommand;
@property (nonatomic, strong) NSString* continueCommand;
@end

@implementation MCBoundingBoxDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect bounds = self.view.bounds;
    CGRect insetBounds = CGRectMake(bounds.origin.x, bounds.origin.y+32, bounds.size.width, bounds.size.height-20);
    self.tableView = [[UITableView alloc] initWithFrame: insetBounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    [self.tableView setBackgroundColor:[UIColor whiteColor]];
    _startBoundingBoxCommand = @"startBoundingBox";
    _continueCommand = @"continue";
    self.swipeEnabled = NO;
    
    [self registerCellTypes];
    [self initCellArray];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;

    [self.view addSubview:self.tableView];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(boundingBoxDrawn:) name:@"boundingBoxResults" object:nil];
//    [self addDragHandle];
    [self addCloseButton];
    
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
}


- (void) initCellArray {
    _cellArray = [[NSMutableArray alloc] init];
    
    MCButtonCell *buttonCell = [_tableView dequeueReusableCellWithIdentifier:@"button"];
    [buttonCell.button setTitle:@"Draw bounds of tile layer" forState:UIControlStateNormal];
    buttonCell.action = _startBoundingBoxCommand;
    buttonCell.delegate = self;
    [_cellArray addObject:buttonCell];
}


#pragma mark - UITableViewDelegate methods
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [_cellArray objectAtIndex:indexPath.row];
}


-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cellArray count];
}


- (void)boundingBoxDrawn:(NSNotification *) notification {
    NSDictionary *userInfo = notification.userInfo;
    // TODO replace with static string for key
    _boundingBox = (GPKGBoundingBox*)userInfo[@"boundingBox"];
    
    [_cellArray removeAllObjects];
    MCButtonCell *buttonCell = [_tableView dequeueReusableCellWithIdentifier:@"button"];
    [buttonCell.button setTitle:@"Continue" forState:UIControlStateNormal];
    buttonCell.action = _continueCommand;
    buttonCell.delegate = self;
    [_cellArray addObject:buttonCell];
    MCDesctiptionCell *description = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    description.descriptionLabel.text = @"You can drag again to change the bounding box.";
    [_cellArray addObject:description];
    [_tableView reloadData];
}


#pragma mark - ButtonCellDelegate
- (void) performButtonAction:(NSString *)action {
    if ([action isEqualToString:_startBoundingBoxCommand]) {
        // send out message about starting bounding box
        // MCMapViewController is listening for this
        [[NSNotificationCenter defaultCenter] postNotificationName:@"drawBoundingBox" object:nil];
        
        // setup description cell
        MCDesctiptionCell *description = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
        description.descriptionLabel.text = @"Long press on the map and drag to select the area where you want to download tiles.";
        [_cellArray removeAllObjects];
        [_cellArray addObject:description];
        [self.tableView reloadData];
        
        // register to listen for bbox complete message
    } else if ([action isEqualToString:_continueCommand]) {
        // call the delegate method to complete the boundingbox step of the wizard
        NSLog(@"Bounding box confirmed, continuing with the wizard.");
        [_boundingBoxDetailsDelegate boundingBoxDetailsCompletionHandler:_boundingBox];
    }
}


#pragma mark - NGADrawerView methods
- (void) closeDrawer {
    [self.boundingBoxDetailsDelegate cancelBoundingBox];
    [self.drawerViewDelegate popDrawer];
}

@end
