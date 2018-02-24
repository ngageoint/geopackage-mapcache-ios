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
@property (nonatomic, strong) GPKGSFieldWithTitleCell *upperLeftLatitudeCell;
@property (nonatomic, strong) GPKGSFieldWithTitleCell *upperLeftLongitudeCell;
@property (nonatomic, strong) GPKGSFieldWithTitleCell *lowerRightLatitudeCell;
@property (nonatomic, strong) GPKGSFieldWithTitleCell *lowerRightLongitudeCell;
@property (nonatomic, strong) GPKGSButtonCell *buttonCell;
@property (nonatomic, strong) GPKGBoundingBox *boundingBox;
@end

@implementation MCManualBoundingBoxViewController

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
    
    _upperLeftLatitudeCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _upperLeftLatitudeCell.title.text = @"Upper left latitude";
    _upperLeftLatitudeCell.field.delegate = self;
    [_cellArray addObject:_upperLeftLatitudeCell];
    
    _upperLeftLongitudeCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _upperLeftLongitudeCell.title.text = @"Upper left longitude";
    _upperLeftLongitudeCell.field.delegate = self;
    [_cellArray addObject:_upperLeftLongitudeCell];
    
    _lowerRightLatitudeCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _lowerRightLatitudeCell.title.text = @"Lower right latitude";
    _lowerRightLatitudeCell.field.delegate = self;
    [_cellArray addObject:_lowerRightLatitudeCell];
    
    _lowerRightLongitudeCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _lowerRightLongitudeCell.title.text = @"Lower right longitude";
    _lowerRightLongitudeCell.field.delegate = self;
    [_cellArray addObject:_lowerRightLongitudeCell];
    
    _buttonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [_buttonCell.button setTitle:@"OK" forState:UIControlStateNormal];
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
    [_delegate manualBoundingBoxCompletionHandler:_boundingBox];
}


#pragma mark- UITextFieldDelegate methods
- (void) textFieldDidEndEditing:(UITextField *)textField {
    // validate data
    // enable or disable button accordingly
    
    [textField resignFirstResponder];
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}
@end
