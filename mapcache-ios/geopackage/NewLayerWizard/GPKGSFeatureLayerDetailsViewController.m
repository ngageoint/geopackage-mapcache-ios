//
//  GPKGSFeatureLayerDetailsViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/12/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "GPKGSFeatureLayerDetailsViewController.h"

@interface GPKGSFeatureLayerDetailsViewController ()
@property (strong, nonatomic) NSMutableArray *cellArray;
@property (strong, nonatomic) UIPickerView *pickerView;
@end

@implementation GPKGSFeatureLayerDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self registerCellTypes];
    [self initCellArray];
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    _tableView.estimatedRowHeight = 100;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.separatorStyle = UIAccessibilityTraitNone;
    [_tableView setBackgroundColor:[UIColor colorWithRed:(229/255.0) green:(230/255.0) blue:(230/255.0) alpha:1]];
    
    _pickerView = [[UIPickerView alloc] init];
    _pickerView.delegate = self;
    _pickerView.dataSource = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSFieldWithTitleCell" bundle:nil] forCellReuseIdentifier:@"fieldWithTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSSectionTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
}


- (void) initCellArray {
    _cellArray = [[NSMutableArray alloc] init];
    
    GPKGSSectionTitleCell *titleCell = [_tableView dequeueReusableCellWithIdentifier:@"title"];
    titleCell.sectionTitleLabel.text = @"New Feature Layer";
    [_cellArray addObject:titleCell];
    
    GPKGSFieldWithTitleCell *layerNameCell = [_tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    layerNameCell.title.text = @"Layer name";
    [_cellArray addObject:layerNameCell];
    
}


#pragma mark - Table View delegate methods
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [_cellArray objectAtIndex:indexPath.row];
}

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cellArray count];
}


#pragma mark - Picker View delegate methods
- (NSInteger)numberOfComponentsInPickerView:(nonnull UIPickerView *)pickerView {
    return 1;
}


- (NSInteger)pickerView:(nonnull UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return 1;
}


- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return @"ohai";
}


- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    // TODO handle this
}




@end

