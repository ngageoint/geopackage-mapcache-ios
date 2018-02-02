//
//  GPKGSTileLayerDetailsViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/9/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "GPKGSTileLayerDetailsViewController.h"

@interface GPKGSTileLayerDetailsViewController ()
@property (strong, nonatomic) NSMutableArray *cellArray;
@property (strong, nonatomic) GPKGSButtonCell *buttonCell;
@end

@implementation GPKGSTileLayerDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerCellTypes];
    [self initCellArray];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    self.tableView.estimatedRowHeight = 100;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.separatorStyle = UIAccessibilityTraitNone;
    [self.tableView setBackgroundColor:[UIColor whiteColor]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) initCellArray {
    _cellArray = [[NSMutableArray alloc] init];
    
    GPKGSSectionTitleCell *titleCell = [self.tableView dequeueReusableCellWithIdentifier:@"title"];
    titleCell.sectionTitleLabel.text = @"New Tile Layer";
    [_cellArray addObject:titleCell];
    
    GPKGSFieldWithTitleCell *layerNameCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    layerNameCell.title.text = @"Name your new layer";
    [_cellArray addObject:layerNameCell];
    
    
    GPKGSDesctiptionCell *tilesDescription = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    tilesDescription.descriptionLabel.text = @"Tile layers consist of a pyramid of images within a geographic extent and zoom levels.";
    [_cellArray addObject:tilesDescription];
    
    GPKGSFieldWithTitleCell *urlCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    urlCell.title.text = @"What is the URL to your tiles?";
    urlCell.field.placeholder = @"http://openstreetmap.org/{x}/{y}/{z}";
    [_cellArray addObject:urlCell];
    
    GPKGSDesctiptionCell *urlDescription = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    urlDescription.descriptionLabel.text = @"Tip: Enter the full URL to the tile server with any of the following template options {x}, {y}, {z}, {minLat}, {minLon}, {maxLat}, {maxLon}.";
    [_cellArray addObject:urlDescription];
    
    GPKGSSegmentedControlCell *referenceSystemSelector = [self.tableView dequeueReusableCellWithIdentifier:@"segmentedControl"];
    referenceSystemSelector.label.text = @"Spatial Reference System";
    NSArray *referenceSystems = [[NSArray alloc] initWithObjects:@"EPSG 3857", @"EPSG 4326", nil];
    [referenceSystemSelector setItems:referenceSystems];
    [_cellArray addObject:referenceSystemSelector];
    
    _buttonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [_buttonCell.button setTitle:@"Next" forState:UIControlStateNormal];
    _buttonCell.delegate = self;
    [_cellArray addObject:_buttonCell];
    
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSFieldWithTitleCell" bundle:nil] forCellReuseIdentifier:@"fieldWithTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSSectionTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSSegmentedControlCell" bundle:nil] forCellReuseIdentifier:@"segmentedControl"];
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
}


- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    return [_cellArray objectAtIndex:indexPath.row];
}


-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cellArray count];
}


#pragma mark - GPKGSSegmentedControlDelegate methods

#pragma mark - GPKGSButtonCellDelegate methods
- (void) performButtonAction:(NSString *)action {
    
}

@end
