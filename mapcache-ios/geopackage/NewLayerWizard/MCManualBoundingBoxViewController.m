//
//  MCManualBoundingBoxViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/23/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCManualBoundingBoxViewController.h"

@interface MCManualBoundingBoxViewController ()
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic) double lowerLeftLat;
@property (nonatomic) double lowerLeftLon;
@property (nonatomic) double upperRightLat;
@property (nonatomic) double upperRightLon;
@property (nonatomic, strong) MCFieldWithTitleCell *lowerLeftLatitudeCell;
@property (nonatomic, strong) MCFieldWithTitleCell *lowerLeftLongitudeCell;
@property (nonatomic, strong) MCFieldWithTitleCell *upperRightLatitudeCell;
@property (nonatomic, strong) MCFieldWithTitleCell *upperRightLongitudeCell;
@property (nonatomic, strong) MCButtonCell *buttonCell;
@property (nonatomic, strong) MCDesctiptionCell *descriptionCell; // TODO spell this right...
@property (nonatomic, strong) GPKGBoundingBox *boundingBox;
@end

@implementation MCManualBoundingBoxViewController

- (instancetype) initWithLowerLeftLat:(double)lowerLeftLat andLowerLeftLon:(double)lowerLeftLon andUpperRightLat:(double)upperRightLat andUpperRightLon:(double)upperRightLon {
    self = [super init];
    
    _lowerLeftLat = lowerLeftLat;
    _lowerLeftLon = lowerLeftLon;
    _upperRightLat = upperRightLat;
    _upperRightLon = upperRightLon;
    
    return self;
}


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


- (void)initCellArray {
    _cellArray = [[NSMutableArray alloc] init];
    
    MCSectionTitleCell *titleCell = [self.tableView dequeueReusableCellWithIdentifier:@"title"];
    titleCell.sectionTitleLabel.text = @"Edit Bounding Box";
    [_cellArray addObject:titleCell];
    
    _lowerLeftLatitudeCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _lowerLeftLatitudeCell.title.text = @"Lower left latitude";
    _lowerLeftLatitudeCell.field.text = [NSString stringWithFormat:@"%f", _lowerLeftLat];
    _lowerLeftLatitudeCell.field.delegate = self;
    [_lowerLeftLatitudeCell.field setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
    [_cellArray addObject:_lowerLeftLatitudeCell];
    
    _lowerLeftLongitudeCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _lowerLeftLongitudeCell.title.text = @"Lower left longitude";
    _lowerLeftLongitudeCell.field.text = [NSString stringWithFormat:@"%f", _lowerLeftLon];
    _lowerLeftLongitudeCell.field.delegate = self;
    [_lowerLeftLongitudeCell.field setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
    [_cellArray addObject:_lowerLeftLongitudeCell];
    
    _upperRightLatitudeCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _upperRightLatitudeCell.title.text = @"Upper right latitude";
    _upperRightLatitudeCell.field.text = [NSString stringWithFormat:@"%f", _upperRightLat];
    _upperRightLatitudeCell.field.delegate = self;
    [_upperRightLatitudeCell.field setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
    [_cellArray addObject:_upperRightLatitudeCell];
    
    _upperRightLongitudeCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _upperRightLongitudeCell.title.text = @"Upper right longitude";
    _upperRightLongitudeCell.field.text = [NSString stringWithFormat:@"%f", _upperRightLon];
    _upperRightLongitudeCell.field.delegate = self;
    [_upperRightLongitudeCell.field setKeyboardType:UIKeyboardTypeNumbersAndPunctuation];
    [_cellArray addObject:_upperRightLongitudeCell];
    
    _descriptionCell = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    _descriptionCell.descriptionLabel.text = @"ohai";
    [_cellArray addObject:_descriptionCell];
    
    _buttonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [_buttonCell.button setTitle:@"OK" forState:UIControlStateNormal];
    [_buttonCell disableButton];
    _buttonCell.delegate = self;
    [_cellArray addObject:_buttonCell];
}


- (void)registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCSectionTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCFieldWithTitleCell" bundle:nil] forCellReuseIdentifier:@"fieldWithTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCSDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCSButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _cellArray.count;
}


- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    return [_cellArray objectAtIndex:indexPath.row];
}


- (void)performButtonAction:(NSString *)action {
    [self dismissViewControllerAnimated:YES completion:nil];
    [_delegate manualBoundingBoxCompletionHandlerWithLowerLeftLat:_lowerLeftLat andLowerLeftLon:_lowerLeftLon andUpperRightLat:_upperRightLat andUpperRightLon:_upperRightLon];
}


#pragma mark- UITextFieldDelegate methods
- (void) textFieldDidEndEditing:(UITextField *)textField {
    [textField resignFirstResponder];
    
    _lowerLeftLat = [_lowerLeftLatitudeCell.field.text doubleValue];
    _lowerLeftLon = [_lowerLeftLongitudeCell.field.text doubleValue];
    _upperRightLat = [_upperRightLatitudeCell.field.text doubleValue];
    _upperRightLon = [_upperRightLongitudeCell.field.text doubleValue];
    
    if (_lowerLeftLat < _upperRightLat && _lowerLeftLon < _upperRightLon) {
        [_buttonCell enableButton];
    } else {
        _descriptionCell.descriptionLabel.text = @"Lower left values should be less than upper right values.";
        [_buttonCell disableButton];
    }
    
    if (_lowerLeftLat > 90 || _upperRightLat > 90 || _lowerLeftLat < -90 || _upperRightLat < -90 || _lowerLeftLon > 180 || _upperRightLon > 180 || _lowerLeftLon < -180 || _upperRightLon < -180) {
        _descriptionCell.descriptionLabel.text = @"Latitude should be between -90 and 90, longitude values should be between -180 and -180.";
        [_buttonCell disableButton];
    }
}


- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    NSCharacterSet *characterSet = [[NSCharacterSet characterSetWithCharactersInString:@"01234567890-."] invertedSet];
    NSString *filtered = [[string componentsSeparatedByCharactersInSet:characterSet] componentsJoinedByString:@""];

    int numberOfDecimals = [[textField.text componentsSeparatedByString:@"."] count] - 1;
    if (numberOfDecimals == 1 && [filtered isEqualToString:@"."]) {
        return false;
    }
    
    if ([filtered isEqualToString:@"-"] && range.location > 0) {
        return false;
    }
    
    return [string isEqualToString:filtered];
}


@end
