 //
//  MCMapPointDataViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 4/16/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "MCMapPointDataViewController.h"


@interface MCMapPointDataViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) MCFieldWithTitleCell *titleCell;
@property (nonatomic, strong) MCTextViewCell *descriptionCell;
@property (nonatomic, strong) MCDualButtonCell *buttonsCell;
@end

@implementation MCMapPointDataViewController

- (instancetype) initWithMapPoint:(GPKGMapPoint *)mapPoint row:(GPKGUserRow *)row asFullView:(BOOL)fullView drawerDelegate:(id<NGADrawerViewDelegate>) drawerDelegate pointDataDelegate:(id<MCMapPointDataDelegate>) pointDataDelegate {
    self = [super initAsFullView:fullView];
    self.mapPoint = mapPoint;
    self.drawerViewDelegate = drawerDelegate;
    self.mapPointDataDelegate = pointDataDelegate;
    self.queriedRow = row;
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] init];
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
    UIEdgeInsets tabBarInsets = UIEdgeInsetsMake(0, 0, self.tabBarController.tabBar.frame.size.height, 0);
    self.tableView.contentInset = tabBarInsets;
    self.tableView.scrollIndicatorInsets = tabBarInsets;
    [self.view addSubview:self.tableView];
    
    [self registerCellTypes];
    
    if (self.isInEditMode) {
        [self showEditMode];
    } else {
        [self showDisplayMode];
    }
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    [self addDragHandle];
    [self addCloseButton];
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCFieldWithTitleCell" bundle:nil] forCellReuseIdentifier:@"fieldWithTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTextViewCell" bundle:nil] forCellReuseIdentifier:@"textView"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDualButtonCell" bundle:nil] forCellReuseIdentifier:@"buttons"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTitleCell" bundle:nil] forCellReuseIdentifier:@"titleDisplay"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDescriptionCell" bundle:nil] forCellReuseIdentifier:@"descriptionDisplay"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCKeyValueDisplayCell" bundle:nil] forCellReuseIdentifier:@"keyValue"];
}


/**
    Show the key-value pairs for the feature row. Currently only displaying text and numbers.
 */
- (void)showDisplayMode {
    _cellArray = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < _queriedRow.columnCount; i++) {
        NSString *columnName = _queriedRow.columnNames[i];
        
        if (![columnName isEqualToString:@"id"] && ![columnName isEqualToString:@"geom"]) {
            MCKeyValueDisplayCell *displayCell = [self.tableView dequeueReusableCellWithIdentifier:@"keyValue"];
            
            if (_queriedRow.columns.columns[i].dataType == GPKG_DT_TEXT) {
                if (!_queriedRow.values[i] || [_queriedRow.values[i] isEqualToString:@""]) {
                    [displayCell setValueLabelText:@"none"];
                } else {
                    [displayCell setValueLabelText: _queriedRow.values[i]];
                }
            } else if (_queriedRow.columns.columns[i].dataType == GPKG_DT_INTEGER || _queriedRow.columns.columns[i].dataType == GPKG_DT_REAL) {
                [displayCell setValueLabelText: [_queriedRow.values[i] stringValue]];
            } else if (_queriedRow.columns.columns[i].dataType == GPKG_DT_BLOB) {
                [displayCell setValueLabelText: @"Binary data, unable to display"];
            }
            
            [displayCell setKeyLabelText:columnName];
            [_cellArray addObject:displayCell];
        }
    }
    
    if (_queriedRow.columnCount == 2) {
        
    }
    
    MCButtonCell *buttonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [buttonCell usePrimaryColors];
    buttonCell.delegate = self;
    [buttonCell setAction:@"edit"];
    [buttonCell setButtonLabel:@"Edit"];
    [_cellArray addObject:buttonCell];
    
    MCButtonCell *deleteButtonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [deleteButtonCell useRedColor];
    deleteButtonCell.delegate = self;
    [deleteButtonCell setAction:@"delete"];
    [deleteButtonCell setButtonLabel:@"Delete"];
    [_cellArray addObject:deleteButtonCell];
    
    [_tableView reloadData];
    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    self.isInEditMode = NO;
    // TODO add empty state
}


/**
    Take the contents of the queried feature row and show the appropriate edit control and keyboard type based on the datatype of the database column.
 */
- (void)showEditMode {
    _cellArray = [[NSMutableArray alloc] init];
    
    if (_queriedRow) {
        for (int i = 0; i < _queriedRow.columnCount; i++) {
            NSString *columnName = _queriedRow.columnNames[i];
            
            if (![columnName isEqualToString:@"id"] && ![columnName isEqualToString:@"geom"]) {
                MCFieldWithTitleCell *fieldWithTitle = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
                [fieldWithTitle setTitleText:columnName];
                fieldWithTitle.columnName = columnName;
                [fieldWithTitle setTextFielDelegate:self];
                
                if (_queriedRow.columns.columns[i].dataType == GPKG_DT_TEXT) {
                    [fieldWithTitle setFieldText:_queriedRow.values[i]];
                    [fieldWithTitle useReturnKeyDone];
                    [_cellArray addObject:fieldWithTitle];
                } else if (_queriedRow.columns.columns[i].dataType == GPKG_DT_INTEGER || _queriedRow.columns.columns[i].dataType == GPKG_DT_REAL) {
                    [fieldWithTitle setFieldText:[_queriedRow.values[i] stringValue]];
                    [fieldWithTitle setupNumericalKeyboard];
                    [_cellArray addObject:fieldWithTitle];
                }
            }
        }
    }
    
    // TODO: Decide what happens for new feature layers. Default set of columns?
    
    _buttonsCell = [self.tableView dequeueReusableCellWithIdentifier:@"buttons"];
    [_buttonsCell setLeftButtonLabel:@"Cancel"];
    [_buttonsCell setLeftButtonAction:@"cancel"];
    [_buttonsCell setRightButtonLabel:@"Save"];
    [_buttonsCell setRightButtonAction:@"save"];
    _buttonsCell.dualButtonDelegate = self;
    [_cellArray addObject:_buttonsCell];
    [_tableView reloadData];
    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    self.isInEditMode = YES;
}


- (void)reloadWith:(GPKGUserRow *)row mapPoint:(GPKGMapPoint *)mapPoint {
    self.queriedRow = row;
    self.mapPoint = mapPoint;
    [self showDisplayMode];
}


#pragma mark - UITableViewDelegate methods
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    return [self.cellArray objectAtIndex:indexPath.row];
}


-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.cellArray count];
}


#pragma mark- UITextFieldDelegate methods
- (void)textFieldDidEndEditing:(UITextField *)textField {
    for (UITableViewCell *cell in self.cellArray) {
        if ([cell isKindOfClass:MCFieldWithTitleCell.class]) {
            MCFieldWithTitleCell *fieldWithTitleCell = (MCFieldWithTitleCell *)cell;
            if (fieldWithTitleCell.field == textField) {
                for (int i = 0; i < self.queriedRow.columns.columns.count; i++) {
                    if ([fieldWithTitleCell.columnName isEqualToString:self.queriedRow.columns.columns[i].name]) {
                        self.queriedRow.values[i] = [fieldWithTitleCell fieldValue];
                    }
                }
            }
        }
    }
}


- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - MCDualButtonCellDelegate methods
- (void)performDualButtonAction:(NSString *)action {
    if ([action isEqualToString:@"save"]) {
        NSLog(@"Saving point data");
        NSString *databaseName = [self.mapPoint.data valueForKey:@"database"];
        BOOL saved = [_mapPointDataDelegate saveRow:_queriedRow toDatabase:databaseName];
        
        if (saved) {
            [self showDisplayMode];
        }
        
    } else if ([action isEqualToString:@"edit"]) {
        // TODO Add switch to edit mode
        NSLog(@"Editing point");
        
        if (self.isInEditMode == NO) {
            [self showEditMode];
        } else {
            [self showDisplayMode];
        }
    } else if ([action isEqualToString:@"cancel"]) {
        NSLog(@"Canceling point edit");
        [self.drawerViewDelegate popDrawer];
    }
}


- (void)performButtonAction:(NSString *)action {
    if ([action isEqualToString:@"edit"]) {
        // TODO Add switch to edit mode
        NSLog(@"Editing point");
        
        if (self.isInEditMode == NO) {
            [self showEditMode];
            self.isInEditMode = YES;
        } else {
            [self showDisplayMode];
            self.isInEditMode = NO;
        }
    } else if ([action isEqualToString:@"delete"]) {
        NSString *databaseName = [self.mapPoint.data valueForKey:@"database"];
        int rowsDeleted = [_mapPointDataDelegate deleteRow:_queriedRow fromDatabase:databaseName andRemoveMapPoint:_mapPoint];
        if (rowsDeleted > 0) {
            [self.drawerViewDelegate popDrawer];
        }
    }
}


#pragma mark - NGADrawerView methods
- (void) closeDrawer {
    [self.drawerViewDelegate popDrawer];
    [self.mapPointDataDelegate mapPointDataViewClosed];
}


@end
