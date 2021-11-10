//
//  GPKGSFeatureLayerDetailsViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/12/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCFeatureLayerDetailsViewController.h"

@interface MCFeatureLayerDetailsViewController ()
@property (strong, nonatomic) NSMutableArray *cellArray;
@property (strong, nonatomic) UIPickerView *pickerView;
@property (strong, nonatomic) NSArray *geometryTypes;
@property (strong, nonatomic) NSDictionary *geometryTypesDictionary;
@property (strong, nonatomic) NSString *selectedGeometryType;
@property (strong, nonatomic) UITableView *tableView;
@property (strong, nonatomic) GPKGGeoPackageManager *manager;
@property (strong, nonatomic) MCSectionTitleCell *titleCell;
@property (strong, nonatomic) MCFieldWithTitleCell *layerNameCell;
@property (strong, nonatomic) MCButtonCell *buttonCell;
@property (strong, nonatomic) MCDescriptionCell *descriptionCell;
@end

@implementation MCFeatureLayerDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect bounds = self.view.bounds;
    CGRect insetBounds = CGRectMake(bounds.origin.x, bounds.origin.y - 6, bounds.size.width, bounds.size.height);
    self.tableView = [[UITableView alloc] initWithFrame: insetBounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    //self.tableView.estimatedRowHeight = 390.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    self.tableView.backgroundColor = [UIColor clearColor];
    
    _geometryTypes = [MCProperties getArrayOfProperty:GPKGS_PROP_EDIT_FEATURES_GEOMETRY_TYPES];
    _geometryTypesDictionary = [MCProperties getDictionaryOfProperty:GPKGS_PROP_EDIT_FEATURES_GEOMETRY_TYPES_DICTIONARY];
    
    [self registerCellTypes];
    [self initCellArray];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.estimatedRowHeight = 100;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.separatorStyle = UIAccessibilityTraitNone;
    [self.view addSubview:self.tableView];
    [self addCloseButton];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCFieldWithTitleCell" bundle:nil] forCellReuseIdentifier:@"fieldWithTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCSectionTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCPickerViewCell" bundle:nil] forCellReuseIdentifier:@"picker"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
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
    
    _buttonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    _buttonCell.delegate = self;
    _buttonCell.action = GPKGS_ACTION_NEW_FEATURE_LAYER;
    [_buttonCell.button setTitle:@"Create Layer" forState:UIControlStateNormal];
    
    if ([_layerNameCell.field.text isEqualToString:@""]) {
        [_buttonCell disableButton];
    } else {
        [_buttonCell enableButton];
    }
    
    [_cellArray addObject:_buttonCell];
    
    _descriptionCell = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    [_descriptionCell setDescription:@"\n\n"];
    [_cellArray addObject:_descriptionCell];
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
    if ([[_layerNameCell fieldValue] isEqualToString:@""]) {
        [_buttonCell disableButton];
    } else if ([_database hasTableNamed:[_layerNameCell fieldValue]]) {
        [_buttonCell disableButton];
        [_layerNameCell useErrorAppearance];
        [_descriptionCell setDescription:@"This GeoPackage already has a layer with that name, please choose a new one."];
    } else {
        [_layerNameCell useNormalAppearance];
        [_buttonCell enableButton];
    }
    
    [textField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


- (void) closeDrawer {
    [self.drawerViewDelegate popDrawer];
}



#pragma mark - GPKGSButtonCellDelegate
- (void) performButtonAction:(NSString *) action {
    if ([action isEqualToString:GPKGS_ACTION_NEW_FEATURE_LAYER]) {
        @try {
            
            NSString * tableName = _layerNameCell.field.text;
            if(tableName == nil || [tableName length] == 0){
                [NSException raise:@"Table Name" format:@"Table name is required"];
            }
            
            GPKGBoundingBox * boundingBox = [[GPKGBoundingBox alloc] init];
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
            
            _selectedGeometryType = [_geometryTypesDictionary valueForKey:@"Geometry"];
            enum SFGeometryType geometryType = [SFGeometryTypes fromName:_selectedGeometryType];
            
            GPKGGeometryColumns * geometryColumns = [[GPKGGeometryColumns alloc] init];
            [geometryColumns setTableName:tableName];
            [geometryColumns setColumnName:@"geom"];
            
            [geometryColumns setGeometryType: geometryType];
            [geometryColumns setZ:[NSNumber numberWithInt:0]];
            [geometryColumns setM:[NSNumber numberWithInt:0]];
            
            [_delegate createFeatueLayerIn:_database.name withGeomertyColumns:geometryColumns andBoundingBox:boundingBox andSrsId:[NSNumber numberWithInt:PROJ_EPSG_WORLD_GEODETIC_SYSTEM]];
        }
        @catch (NSException *e) {
            if(self.delegate != nil){
                NSLog(@"There was a problem in FeatureDetailsViewController when making a new layer: %@", e.reason);
            }
        }
    }
}


@end

