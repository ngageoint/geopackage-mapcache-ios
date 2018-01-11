//
//  GPKGSTileLayerDetailsViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/9/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "GPKGSTileLayerDetailsViewController.h"

@interface GPKGSTileLayerDetailsViewController ()
//@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) NSMutableArray *cellArray;
@end

@implementation GPKGSTileLayerDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerCellTypes];
    [self initCellArray];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    UIEdgeInsets insets = UIEdgeInsetsMake(60, 0, 0, 0);
    self.tableView.contentInset = insets;
    self.tableView.estimatedRowHeight = 100;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.separatorStyle = UIAccessibilityTraitNone;
    
    [self.tableView setBackgroundColor:[UIColor colorWithRed:(229/255.0) green:(230/255.0) blue:(230/255.0) alpha:1]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) initCellArray {
    _cellArray = [[NSMutableArray alloc] init];
    
    GPKGSFieldWithTitleCell *layerNameCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    layerNameCell.title.text = @"Name your new layer";
    [_cellArray addObject:layerNameCell];
    
    
    GPKGSDesctiptionCell *tilesDescription = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    tilesDescription.descriptionLabel.text = @"Tile layers consist of a pyramid of images within a geographic extent and zoom levels.";
    [_cellArray addObject:tilesDescription];
    
    GPKGSFieldWithTitleCell *urlCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    urlCell.title.text = @"What is the URL to your tiles?";
    urlCell.field.text = @"http://openstreetmap.org/{x}/{y}/{z}";
    [_cellArray addObject:urlCell];
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSFieldWithTitleCell" bundle:nil] forCellReuseIdentifier:@"fieldWithTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
}


- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    NSLog(@"cell count %D, and indexPath row %D", [_cellArray count], indexPath.row);
    return [_cellArray objectAtIndex:indexPath.row];
}


-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cellArray count];
}

@end
