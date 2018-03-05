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
@property (nonatomic, strong) GPKGSFieldWithTitleCell *lowerLeftLatitudeCell;
@property (nonatomic, strong) GPKGSFieldWithTitleCell *lowerLeftLongitudeCell;
@property (nonatomic, strong) GPKGSFieldWithTitleCell *upperRightLatitudeCell;
@property (nonatomic, strong) GPKGSFieldWithTitleCell *upperRightLongitudeCell;
@property (nonatomic, strong) GPKGSButtonCell *buttonCell;
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
    
    GPKGSSectionTitleCell *titleCell = [self.tableView dequeueReusableCellWithIdentifier:@"title"];
    titleCell.sectionTitleLabel.text = @"Edit Bounding Box";
    [_cellArray addObject:titleCell];
    
    _lowerLeftLatitudeCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _lowerLeftLatitudeCell.title.text = @"Lower left latitude";
    _lowerLeftLatitudeCell.field.text = [NSString stringWithFormat:@"%f", _lowerLeftLat];
    _lowerLeftLatitudeCell.field.delegate = self;
    [_cellArray addObject:_lowerLeftLatitudeCell];
    
    _lowerLeftLongitudeCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _lowerLeftLongitudeCell.title.text = @"Lower left longitude";
    _lowerLeftLongitudeCell.field.text = [NSString stringWithFormat:@"%f", _lowerLeftLon];
    _lowerLeftLongitudeCell.field.delegate = self;
    [_cellArray addObject:_lowerLeftLongitudeCell];
    
    _upperRightLatitudeCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _upperRightLatitudeCell.title.text = @"Upper right latitude";
    _upperRightLatitudeCell.field.text = [NSString stringWithFormat:@"%f", _upperRightLat];
    _upperRightLatitudeCell.field.delegate = self;
    [_cellArray addObject:_upperRightLatitudeCell];
    
    _upperRightLongitudeCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _upperRightLongitudeCell.title.text = @"Upper right longitude";
    _upperRightLongitudeCell.field.text = [NSString stringWithFormat:@"%f", _upperRightLon];
    _upperRightLongitudeCell.field.delegate = self;
    [_cellArray addObject:_upperRightLongitudeCell];
    
    _buttonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [_buttonCell.button setTitle:@"OK" forState:UIControlStateNormal];
    [_buttonCell disableButton];
    _buttonCell.delegate = self;
    [_cellArray addObject:_buttonCell];
    
}


- (void)registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSSectionTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSFieldWithTitleCell" bundle:nil] forCellReuseIdentifier:@"fieldWithTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"GPKGSButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
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
        [_buttonCell disableButton];
    }
}


- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
@end
