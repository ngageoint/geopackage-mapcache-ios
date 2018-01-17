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
@property (strong, nonatomic) NSArray *geometryTypes;

@property (strong, nonatomic) GPKGSSectionTitleCell *titleCell;
@property (strong, nonatomic) GPKGSFieldWithTitleCell *layerNameCell;
@property (strong, nonatomic) GPKGSFieldWithTitleCell *geometryCell;
@property (strong, nonatomic) GPKGSButtonCell *buttonCell;
@end

@implementation GPKGSFeatureLayerDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _geometryTypes = [GPKGSProperties getArrayOfProperty:GPKGS_PROP_EDIT_FEATURES_GEOMETRY_TYPES];
    
    _pickerView = [[UIPickerView alloc] init];
    _pickerView.delegate = self;
    _pickerView.dataSource = self;
    _pickerView.showsSelectionIndicator = YES;
    
    [self registerCellTypes];
    [self initCellArray];
    
    _tableView.delegate = self;
    _tableView.dataSource = self;
    
    _tableView.estimatedRowHeight = 100;
    _tableView.rowHeight = UITableViewAutomaticDimension;
    _tableView.separatorStyle = UIAccessibilityTraitNone;
    [_tableView setBackgroundColor:[UIColor colorWithRed:(229/255.0) green:(230/255.0) blue:(230/255.0) alpha:1]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSFieldWithTitleCell" bundle:nil] forCellReuseIdentifier:@"fieldWithTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSSectionTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
}


- (void) initCellArray {
    _cellArray = [[NSMutableArray alloc] init];
    
    _titleCell = [_tableView dequeueReusableCellWithIdentifier:@"title"];
    _titleCell.sectionTitleLabel.text = @"New Feature Layer";
    [_cellArray addObject:_titleCell];
    
    _layerNameCell = [_tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _layerNameCell.title.text = @"Layer name";
    [_layerNameCell.field setReturnKeyType:UIReturnKeyDone];
    _layerNameCell.field.delegate = self;
    [_cellArray addObject:_layerNameCell];
    
    _geometryCell = [_tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _geometryCell.title.text = @"Geometry Type";
    _geometryCell.field.placeholder = @"Select a geometry type";
    _geometryCell.field.inputView = _pickerView;
    [_cellArray addObject:_geometryCell];
    
    _buttonCell = [_tableView dequeueReusableCellWithIdentifier:@"button"];
    _buttonCell.button.titleLabel.text = @"Create Layer";
    
    [_cellArray addObject:_buttonCell];
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
    return [_geometryTypes count];
}


- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [_geometryTypes objectAtIndex:row];
}


- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    _geometryCell.field.text = [_geometryTypes objectAtIndex:row];
    [_geometryCell.field resignFirstResponder];
}


#pragma mark - UITextFieldDelegate
- (void) textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

@end

