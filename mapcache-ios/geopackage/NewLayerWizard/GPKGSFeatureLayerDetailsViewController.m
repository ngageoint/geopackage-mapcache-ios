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
@property (strong, nonatomic) NSDictionary *geometryTypesDictionary;
@property (strong, nonatomic) NSString *selectedGeometryType;

@property (strong, nonatomic) GPKGGeoPackageManager *manager;
@property (strong, nonatomic) GPKGSSectionTitleCell *titleCell;
@property (strong, nonatomic) GPKGSFieldWithTitleCell *layerNameCell;
@property (strong, nonatomic) GPKGSPickerViewCell *geometryTypeCell;
@property (strong, nonatomic) GPKGSButtonCell *buttonCell;
@end

@implementation GPKGSFeatureLayerDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _manager = [GPKGGeoPackageFactory getManager];
    _geometryTypes = [GPKGSProperties getArrayOfProperty:GPKGS_PROP_EDIT_FEATURES_GEOMETRY_TYPES];
    _geometryTypesDictionary = [GPKGSProperties getDictionaryOfProperty:GPKGS_PROP_EDIT_FEATURES_GEOMETRY_TYPES_DICTIONARY];
    
    [self registerCellTypes];
    [self initCellArray];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.estimatedRowHeight = 100;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.separatorStyle = UIAccessibilityTraitNone;
    [self.tableView setBackgroundColor:[UIColor colorWithRed:(229/255.0) green:(230/255.0) blue:(230/255.0) alpha:1]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSFieldWithTitleCell" bundle:nil] forCellReuseIdentifier:@"fieldWithTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSSectionTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSPickerViewCell" bundle:nil] forCellReuseIdentifier:@"picker"];
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
}


- (void) initCellArray {
    _cellArray = [[NSMutableArray alloc] init];
    
    _titleCell = [self.tableView dequeueReusableCellWithIdentifier:@"title"];
    _titleCell.sectionTitleLabel.text = @"New Feature Layer";
    [_cellArray addObject:_titleCell];
    
    _layerNameCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _layerNameCell.title.text = @"Layer name";
    [_layerNameCell.field setReturnKeyType:UIReturnKeyDone];
    _layerNameCell.field.delegate = self;
    [_cellArray addObject:_layerNameCell];
    
    _geometryTypeCell = [self.tableView dequeueReusableCellWithIdentifier:@"picker"];
    _geometryTypeCell.label.text = @"Geometry Type";
    _geometryTypeCell.picker.delegate = self;
    _geometryTypeCell.picker.dataSource = self;
    _geometryTypeCell.picker.showsSelectionIndicator = YES;
    [_geometryTypeCell.picker selectRow:[_geometryTypesDictionary.allKeys indexOfObject:@"Geometry"] inComponent:0 animated:YES];
    _selectedGeometryType = [_geometryTypesDictionary valueForKey:@"Geometry"];
    [_cellArray addObject:_geometryTypeCell];
    
    _buttonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    _buttonCell.delegate = self;
    _buttonCell.action = GPKGS_ACTION_NEW_FEATURE_LAYER;
    [_buttonCell.button setTitle:@"Create Layer" forState:UIControlStateNormal];
    
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
    return [_geometryTypesDictionary count];
}


- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [_geometryTypesDictionary.allKeys objectAtIndex:row];
}


- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    _selectedGeometryType = [_geometryTypesDictionary valueForKey:[_geometryTypesDictionary.allKeys objectAtIndex:row]];
}


#pragma mark - UITextFieldDelegate
- (void) textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - GPKGSButtonCellDelegate
- (void) performButtonAction:(NSString *) action {
    if ([action isEqualToString:GPKGS_ACTION_NEW_FEATURE_LAYER]) {
        @try {
            
            NSString * tableName = _layerNameCell.field.text;
            if(tableName == nil || [tableName length] == 0){
                [NSException raise:@"Table Name" format:@"Table name is required"];
            }
            
            GPKGBoundingBox * boundingBox;
            boundingBox.minLatitude = [[NSDecimalNumber alloc] initWithFloat: -90.0f];
            boundingBox.maxLatitude = [[NSDecimalNumber alloc] initWithFloat: 90.0f];
            boundingBox.minLongitude = [[NSDecimalNumber alloc] initWithFloat: -180.0f];
            boundingBox.maxLongitude = [[NSDecimalNumber alloc] initWithFloat: 180.0f];
            
            if ([boundingBox.minLatitude doubleValue] > [boundingBox.maxLatitude doubleValue]) {
                [NSException raise:@"Latitude Range" format:@"Min latitude can not be larger than max latitude"];
            }
            
            if ([boundingBox.minLongitude doubleValue] > [boundingBox.maxLongitude doubleValue]) {
                [NSException raise:@"Longitude Range" format:@"Min longitude can not be larger than max longitude"];
            }
            
            enum WKBGeometryType geometryType = [WKBGeometryTypes fromName:_selectedGeometryType];
            
            GPKGGeometryColumns * geometryColumns = [[GPKGGeometryColumns alloc] init];
            [geometryColumns setTableName:tableName];
            [geometryColumns setColumnName:@"geom"];
            [geometryColumns setGeometryType:geometryType];
            [geometryColumns setZ:[NSNumber numberWithInt:0]];
            [geometryColumns setM:[NSNumber numberWithInt:0]];
            
            GPKGGeoPackage * geoPackage = [_manager open:_database.name];
            @try {
                [geoPackage createFeatureTableWithGeometryColumns:geometryColumns andBoundingBox:boundingBox andSrsId:[NSNumber numberWithInt:PROJ_EPSG_WORLD_GEODETIC_SYSTEM]];
            }
            @finally {
                [geoPackage close];
                
                if (_delegate != nil) {
                    [_delegate featureLayerCreationComplete:YES withError:nil];
                }
            }
        }
        @catch (NSException *e) {
            if(self.delegate != nil){
                [_delegate featureLayerCreationComplete:NO withError:e.description];
            }
        }
    }
}

@end

