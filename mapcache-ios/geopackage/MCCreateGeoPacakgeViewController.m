//
//  MCCreateGeoPacakgeViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/30/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "MCCreateGeoPacakgeViewController.h"

@interface MCCreateGeoPacakgeViewController ()
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) MCFieldWithTitleCell *nameCell;
@property (nonatomic, strong) MCButtonCell *buttonCell;
@property (nonatomic, strong) MCDescriptionCell *helpTextCell;
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation MCCreateGeoPacakgeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tableView = [[UITableView alloc] init];
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


- (void) initCellArray {
    _cellArray = [[NSMutableArray alloc] init];
    
    MCTitleCell *title = [self.tableView dequeueReusableCellWithIdentifier:@"title"];
    title.label.text = @"New GeoPackage";
    [_cellArray addObject:title];
    
    _nameCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    [_nameCell setTitleText:@"Name"];
    [_nameCell setTextFielDelegate:self];
    [_nameCell useReturnKeyDone];
    [_cellArray addObject:_nameCell];
    
    _buttonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [_buttonCell.button setTitle:@"Create GeoPackage" forState:UIControlStateNormal];
    [_buttonCell disableButton];
    _buttonCell.delegate = self;
    _buttonCell.action = @"CreateGeoPackage";
    [_cellArray addObject:_buttonCell];
    
    _helpTextCell = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    [_helpTextCell setDescription:@"\n\n"];
    [_cellArray addObject:_helpTextCell];
}


- (void) registerCellTypes {
    [_tableView registerNib:[UINib nibWithNibName:@"MCTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
    [_tableView registerNib:[UINib nibWithNibName:@"MCFieldWithTitleCell" bundle:nil] forCellReuseIdentifier:@"fieldWithTitle"];
    [_tableView registerNib:[UINib nibWithNibName:@"MCDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [_tableView registerNib:[UINib nibWithNibName:@"MCButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
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
    if ([_createGeoPackageDelegate isValidGeoPackageName:textField.text]) {
        [_helpTextCell setDescription:@""];
        [_nameCell useNormalAppearance];
        [_buttonCell enableButton];
    } else {
        [_buttonCell disableButton];
        [_helpTextCell setDescription:@"Make sure your name is not already in use."];
        [_nameCell useErrorAppearance];
    }
}


- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - GPKGSButtonCellDelegate methods
- (void) performButtonAction:(NSString *)action {
    if ([action isEqualToString:@"CreateGeoPackage"]) {
        [self.createGeoPackageDelegate createGeoPackage:[self.nameCell fieldValue]];
        [self.drawerViewDelegate popDrawer];
    }
}


#pragma mark - NGADrawerView methods
- (void) closeDrawer {
    [self.drawerViewDelegate popDrawer];
}

- (BOOL)gestureIsInConflict:(UIPanGestureRecognizer *) recognizer {
    CGPoint point = [recognizer locationInView:self.view];
    
    if (CGRectContainsPoint(_nameCell.frame, point)) {
        return true;
    }
    
    return false;
}


@end
