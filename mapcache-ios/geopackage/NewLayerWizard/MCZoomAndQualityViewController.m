//
//  MCZoomAndQualityViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/7/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCZoomAndQualityViewController.h"

@interface MCZoomAndQualityViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) MCZoomCell *zoomCell;
@property (nonatomic, strong) MCButtonCell *continueButtonCell;
@property (nonatomic, strong) MCButtonCell *backButtonCell;
@property (nonatomic, strong) MCDesctiptionCell *downloadDetailsCell;
@end

@implementation MCZoomAndQualityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] init];
    CGRect bounds = self.view.bounds;
    CGRect insetBounds = CGRectMake(bounds.origin.x, bounds.origin.y + 32, bounds.size.width, bounds.size.height - 20);
    self.tableView = [[UITableView alloc] initWithFrame: insetBounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    UIEdgeInsets tabBarInsets = UIEdgeInsetsMake(0, 0, self.tabBarController.tabBar.frame.size.height, 0);
    self.tableView.contentInset = tabBarInsets;
    self.tableView.scrollIndicatorInsets = tabBarInsets;
    [self.view addSubview:self.tableView];
    
    [self registerCellTypes];
    [self initCellArray];

    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.separatorStyle = UIAccessibilityTraitNone;
    
    [self addDragHandle];
    [self addCloseButton];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) initCellArray {
    _cellArray = [[NSMutableArray alloc] init];
    
    _zoomCell = [self.tableView dequeueReusableCellWithIdentifier:@"zoom"];
    _zoomCell.valueChangedDelegate = self;
    [_cellArray addObject:_zoomCell];
    
    _continueButtonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [_continueButtonCell.button setTitle:@"Create Tile Layer" forState:UIControlStateNormal];
    _continueButtonCell.delegate = self;
    _continueButtonCell.action = @"continue";
    [_cellArray addObject:_continueButtonCell];
    
    _downloadDetailsCell = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    [_downloadDetailsCell setDescription:@"\n\n"];
    [_cellArray addObject: _downloadDetailsCell];
    
    _backButtonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [_backButtonCell useSecondaryColors];
    [_backButtonCell setButtonLabel:@"Adjust bounding box"];
    _backButtonCell.delegate = self;
    _backButtonCell.action = @"back";
    [_cellArray addObject:_backButtonCell];
    
    
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCZoomCell" bundle:nil] forCellReuseIdentifier:@"zoom"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
}


- (void) closeDrawer {
    [super closeDrawer];
    [self.drawerViewDelegate popDrawer];
    [self.zoomAndQualityDelegate cancelZoomAndQuality];
}


#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _cellArray.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    return [_cellArray objectAtIndex:indexPath.row];
}


#pragma mark - MCZoomCellValueChangedDelegate
- (void) zoomValuesChanged:(NSNumber *) minZoom andMaxZoom:(NSNumber *) maxZoom {
    NSString * updatedEstimate = [_zoomAndQualityDelegate updateTileDownloadSizeEstimateWith:minZoom andMaxZoom:maxZoom];
    [_downloadDetailsCell setDescription:updatedEstimate];
}


#pragma mark - GPKGSButtonCellDelegate method
- (void) performButtonAction:(NSString *)action {
    NSLog(@"Button tapped in zoom and format screen");
    
    if ([action isEqualToString:@"continue"]) {
        [_zoomAndQualityDelegate zoomAndQualityCompletionHandlerWith:_zoomCell.minZoom andMaxZoom:_zoomCell.maxZoom];
    } else {
        [_zoomAndQualityDelegate goBackToBoundingBox];
    }
    
}

@end
