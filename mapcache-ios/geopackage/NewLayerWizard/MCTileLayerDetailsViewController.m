//
//  GPKGSTileLayerDetailsViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/9/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCTileLayerDetailsViewController.h"

@interface MCTileLayerDetailsViewController ()
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) MCButtonCell *buttonCell;
@property (nonatomic, strong) MCFieldWithTitleCell *layerNameCell;
@property (nonatomic, strong) MCFieldWithTitleCell *urlCell;
@property (nonatomic, strong) MCSegmentedControlCell *referenceSystemSelector;
@property (nonatomic, strong) NSDictionary *referenceSystems;
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation MCTileLayerDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tableView = [[UITableView alloc] init];
    _referenceSystems = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithInt: 3857], @"EPSG 3857", [NSNumber numberWithInt: 4326], @"EPSG 4326", nil];
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
    [self.tableView setBackgroundColor:[UIColor whiteColor]];
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


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (BOOL)gestureIsInConflict:(UIPanGestureRecognizer *) recognizer {
    CGPoint point = [recognizer locationInView:self.view];
    
    if (CGRectContainsPoint(self.tableView.frame, point)) {
        return true;
    }
    
    return false;
}


- (void) initCellArray {
    _cellArray = [[NSMutableArray alloc] init];
    
    MCTitleCell *title = [self.tableView dequeueReusableCellWithIdentifier:@"title"];
    title.label.text = @"New Tile Layer";
    [_cellArray addObject:title];
    
    _layerNameCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _layerNameCell.title.text = @"Name your new layer";
    [_layerNameCell.field setReturnKeyType:UIReturnKeyDone]; // TODO look into UIReturnKeyNext
    _layerNameCell.field.delegate = self;
    [_cellArray addObject:_layerNameCell];
    
    
    MCDesctiptionCell *tilesDescription = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    tilesDescription.descriptionLabel.text = @"Tile layers consist of a pyramid of images within a geographic extent and zoom levels.";
    [_cellArray addObject:tilesDescription];
    
    _urlCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _urlCell.title.text = @"What is the URL to your tiles?";
    _urlCell.field.placeholder = @"http://openstreetmap.org/{x}/{y}/{z}";
    _urlCell.field.text = @"http://osm.geointservices.io/osm_tiles/{z}/{x}/{y}.png";
    _urlCell.field.delegate = self;
    [_urlCell.field setReturnKeyType:UIReturnKeyDone];
    [_cellArray addObject:_urlCell];
    
    MCDesctiptionCell *urlDescription = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    urlDescription.descriptionLabel.text = @"Tip: Enter the full URL to the tile server with any of the following template options {x}, {y}, {z}, {minLat}, {minLon}, {maxLat}, {maxLon}.";
    [_cellArray addObject:urlDescription];
    
    _referenceSystemSelector = [self.tableView dequeueReusableCellWithIdentifier:@"segmentedControl"];
    _referenceSystemSelector.label.text = @"Spatial Reference System";
    [_referenceSystemSelector setItems:_referenceSystems.allKeys];
    [_cellArray addObject:_referenceSystemSelector];
    
    _buttonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [_buttonCell.button setTitle:@"Next" forState:UIControlStateNormal];
    [_buttonCell disableButton];
    _buttonCell.delegate = self;
    _buttonCell.action = @"BoundingBox";
    [_cellArray addObject:_buttonCell];
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCFieldWithTitleCell" bundle:nil] forCellReuseIdentifier:@"fieldWithTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCSegmentedControlCell" bundle:nil] forCellReuseIdentifier:@"segmentedControl"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
}


#pragma mark - UITableViewDelegate methods
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    return [_cellArray objectAtIndex:indexPath.row];
}


-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cellArray count];
}


#pragma mark- UITextFieldDelegate methods
- (void) textFieldDidEndEditing:(UITextField *)textField {
    if ([_layerNameCell.field.text isEqualToString:@""] || [_urlCell.field.text isEqualToString:@""]) {
        [_buttonCell disableButton];
    } else {
        [_buttonCell enableButton];
    }
    
    [textField resignFirstResponder];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - GPKGSSegmentedControlDelegate methods

#pragma mark - GPKGSButtonCellDelegate methods
- (void) performButtonAction:(NSString *)action {
    NSString *selectedSegmentTitle =  [_referenceSystemSelector.segmentedControl titleForSegmentAtIndex:[_referenceSystemSelector.segmentedControl selectedSegmentIndex]];
    int referenceSystem = [_referenceSystems[selectedSegmentTitle] intValue];
    
    [_delegate tileLayerDetailsCompletionHandlerWithName:_layerNameCell.field.text URL:_urlCell.field.text andReferenceSystemCode:referenceSystem];
}

@end
