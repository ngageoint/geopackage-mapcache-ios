//
//  MCZoomAndQualityViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/7/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCZoomAndQualityViewController.h"

@interface MCZoomAndQualityViewController ()
@property (strong, nonatomic) NSMutableArray *cellArray;
@property (strong, nonatomic) MCZoomCell *zoomCell;
@property (strong, nonatomic) MCSegmentedControlCell *tileFormatCell;
@property (strong, nonatomic) MCButtonCell *buttonCell;
@end

@implementation MCZoomAndQualityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerCellTypes];
    [self initCellArray];

    self.navigationItem.title = @"Tile Storage Options";
    self.tableView.estimatedRowHeight = 100;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.separatorStyle = UIAccessibilityTraitNone;
    [self.tableView setBackgroundColor:[UIColor whiteColor]];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) initCellArray {
    _cellArray = [[NSMutableArray alloc] init];
    
    _zoomCell = [self.tableView dequeueReusableCellWithIdentifier:@"zoom"];
    [_cellArray addObject:_zoomCell];
    
    _tileFormatCell = [self.tableView dequeueReusableCellWithIdentifier:@"segmentedControl"];
    _tileFormatCell.label.text = @"Tile Format";
    NSArray *formats = [[NSArray alloc] initWithObjects: @"GeoPackage", @"Standard", nil];
    [_tileFormatCell setItems:formats];
    [_cellArray addObject:_tileFormatCell];
    
    _buttonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [_buttonCell.button setTitle:@"Create Tile Layer" forState:UIControlStateNormal];
    _buttonCell.delegate = self;
    [_cellArray addObject:_buttonCell];
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCZoomCell" bundle:nil] forCellReuseIdentifier:@"zoom"];
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSSegmentedControlCell" bundle:nil] forCellReuseIdentifier:@"segmentedControl"];
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
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


#pragma mark - UITextFieldDelegate methods
- (void) textFieldDidEndEditing:(UITextField *)textField {
    // TODO check some values and enable or disable the button accordingly
}


- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark -  GPKGSButtonCellDelegate method
- (void) performButtonAction:(NSString *)action {
    NSLog(@"Button tapped in zoom and format screen");
    [_delegate zoomAndQualityCompletionHandlerWith:_zoomCell.minZoom andMaxZoom:_zoomCell.maxZoom];
}

@end
