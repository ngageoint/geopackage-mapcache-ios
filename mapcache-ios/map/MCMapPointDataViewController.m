 //
//  MCMapPointDataViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 4/16/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "MCMapPointDataViewController.h"
#import "mapcache_ios-Swift.h"

@interface MCMapPointDataViewController ()
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) MCFieldWithTitleCell *titleCell;
@property (nonatomic, strong) MCAttachmentsCell *attachmentsCell;
@property (nonatomic, strong) MCTextViewCell *descriptionCell;
@property (nonatomic, strong) MCDualButtonCell *buttonsCell;
@property (nonatomic, strong) MCDualButtonCell *attachmentButtonsCell;
@property (nonatomic, strong) UIImagePickerController *imagePicker;
@property (nonatomic) BOOL haveScrolled;
@end

@implementation MCMapPointDataViewController

- (instancetype) initWithMapPoint:(GPKGMapPoint *)mapPoint row:(GPKGUserRow *)row databaseName:(NSString *)databaseName layerName:(NSString *)layerName mode:(MCMapPointViewMode)mode asFullView:(BOOL)fullView drawerDelegate:(id<NGADrawerViewDelegate>) drawerDelegate pointDataDelegate:(id<MCMapPointDataDelegate>) pointDataDelegate {
    self = [super initAsFullView:fullView];
    self.mapPoint = mapPoint;
    self.databaseName = databaseName;
    self.layerName = layerName;
    self.drawerViewDelegate = drawerDelegate;
    self.mapPointDataDelegate = pointDataDelegate;
    self.mode = mode;
    self.row = row;
    self.media = [[NSMutableArray alloc] init];
    self.addedMedia = [[NSMutableArray alloc] init];
    return self;
}


- (instancetype) initWithMapPoint:(GPKGMapPoint *)mapPoint row:(GPKGUserRow *)row databaseName:(NSString *)databaseName layerName:(NSString *)layerName media:(NSMutableArray *)media mode:(MCMapPointViewMode)mode asFullView:(BOOL)fullView drawerDelegate:(id<NGADrawerViewDelegate>) drawerDelegate pointDataDelegate:(id<MCMapPointDataDelegate>) pointDataDelegate showAttachmentDelegate:(id<MCShowAttachmentDelegate>) showAttachmentDelegate {
    self = [super initAsFullView:fullView];
    self.mapPoint = mapPoint;
    self.databaseName = databaseName;
    self.layerName = layerName;
    self.media = media;
    self.addedMedia = [[NSMutableArray alloc] init];
    self.drawerViewDelegate = drawerDelegate;
    self.mapPointDataDelegate = pointDataDelegate;
    self.showAttachmentDelegate = showAttachmentDelegate;
    self.mode = mode;
    self.row = row;
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
    //self.tableView.estimatedRowHeight = 390.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = UITableViewAutomaticDimension;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    [self.tableView setBackgroundColor:[UIColor clearColor]];
    UIEdgeInsets tabBarInsets = UIEdgeInsetsMake(0, 0, self.tabBarController.tabBar.frame.size.height, 0);
    self.tableView.contentInset = tabBarInsets;
    self.tableView.scrollIndicatorInsets = tabBarInsets;
    [self.view addSubview:self.tableView];
    [self registerCellTypes];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    _imagePicker = [[UIImagePickerController alloc] init];
    _imagePicker.delegate = self;
    
    [self addDragHandle];
    [self addCloseButton];
    self.haveScrolled = NO;
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.mode == MCPointViewModeEdit) {
        [self showEditMode];
    } else {
        [self showDisplayMode];
    }
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCFieldWithTitleCell" bundle:nil] forCellReuseIdentifier:@"fieldWithTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTextViewCell" bundle:nil] forCellReuseIdentifier:@"textView"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDualButtonCell" bundle:nil] forCellReuseIdentifier:@"buttons"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTitleCell" bundle:nil] forCellReuseIdentifier:@"titleDisplay"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDescriptionCell" bundle:nil] forCellReuseIdentifier:@"descriptionDisplay"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCKeyValueDisplayCell" bundle:nil] forCellReuseIdentifier:@"keyValue"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCSwitchCell" bundle:nil] forCellReuseIdentifier:@"switchCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCLayerCell" bundle:nil] forCellReuseIdentifier:@"layerCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCEmptyStateCell" bundle:nil] forCellReuseIdentifier:@"spacer"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCAttachmentsCell" bundle:nil] forCellReuseIdentifier:@"attachmentsCell"];
}


/**
    Show the key-value pairs for the feature row. Currently only displaying text and numbers.
 */
- (void)showDisplayMode {
    _cellArray = [[NSMutableArray alloc] init];
    
    MCLayerCell *details = [self.tableView dequeueReusableCellWithIdentifier:@"layerCell"];
    [details setName:self.databaseName];
    [details setDetails:self.layerName];
    [details activeIndicatorOff];
    [details.layerTypeImage setImage:[UIImage imageNamed:@"Point"]];
    [_cellArray addObject:details];
    
    if (self.media.count > 0) {
        self.attachmentsCell = [self.tableView dequeueReusableCellWithIdentifier:@"attachmentsCell"];
        [self.attachmentsCell setContentsWithMediaArray:self.media];
        self.attachmentsCell.attachmentDelegate = self.showAttachmentDelegate;
        [self.cellArray addObject:self.attachmentsCell];
    }
    
    if (_row.columnCount == 2) { // no user editable columns
        MCDescriptionCell *empty = [self.tableView dequeueReusableCellWithIdentifier:@"descriptionDisplay"];
        [empty setDescription:@"This layer has no fields."];
        [_cellArray addObject:empty];
        
        MCButtonCell *addFieldsButtonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
        [addFieldsButtonCell useSecondaryColors];
        addFieldsButtonCell.delegate = self;
        [addFieldsButtonCell setAction:@"addFields"];
        [addFieldsButtonCell setButtonLabel:@"Add fields"];
        [_cellArray addObject:addFieldsButtonCell];
    }
    
    for (int i = 0; i < _row.columnCount; i++) {
        NSString *columnName = _row.columnNames[i];
        enum GPKGDataType dataType = _row.columns.columns[i].dataType;
        NSString *idColumnName = [_row idColumnName]; // the Primary Key column name
        NSString *geometryColumnName = [(GPKGFeatureRow*)_row geometryColumnName];
        
        if (![columnName isEqualToString:idColumnName] && ![columnName isEqualToString:geometryColumnName]) {
            MCKeyValueDisplayCell *displayCell = [self.tableView dequeueReusableCellWithIdentifier:@"keyValue"];
            
            if (_row.columns.columns[i].dataType == GPKG_DT_TEXT) {
                if (!_row.values[i] || [_row.values[i] isKindOfClass:NSNull.class] || [_row.values[i] isEqualToString:@""]) {
                    [displayCell setValueLabelText:@"none"];
                } else {
                    [displayCell setValueLabelText: _row.values[i]];
                }
            } else if (dataType == GPKG_DT_INTEGER || dataType == GPKG_DT_REAL || dataType == GPKG_DT_DOUBLE || dataType == GPKG_DT_INT || dataType == GPKG_DT_FLOAT || dataType == GPKG_DT_SMALLINT || dataType == GPKG_DT_TINYINT || dataType == GPKG_DT_MEDIUMINT) {
                if ([_row.values[i] respondsToSelector:@selector(stringValue)]) {
                    [displayCell setValueLabelText:[_row.values[i] stringValue]];
                } else if ([_row.values[i] isKindOfClass:NSString.class]) {
                    [displayCell setValueLabelText: _row.values[i]];
                }
            } else if (dataType == GPKG_DT_BLOB) {
                [displayCell setValueLabelText: @"Binary data, unable to display"];
            } else if (dataType == GPKG_DT_BOOLEAN) {
                if ([_row.values[i] isKindOfClass:NSNull.class] || _row.values[i] == nil || [_row.values[i] boolValue] == NO) {
                    [displayCell setValueLabelText:@"false"];
                } else {
                    [displayCell setValueLabelText:@"true"];
                }
                
                
            } else if ([_row.values[i] isKindOfClass:NSNull.class] || _row.values[i] == nil) {
                [displayCell setValueLabelText:@""];
            }
            
            [displayCell setKeyLabelText:columnName];
            [_cellArray addObject:displayCell];
        }
    }
    
    if (_row.columnCount == 2) {
        
    }
    
    MCButtonCell *buttonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [buttonCell usePrimaryColors];
    buttonCell.delegate = self;
    [buttonCell setAction:@"edit"];
    [buttonCell setButtonLabel:@"Edit"];
    [_cellArray addObject:buttonCell];
    
    MCButtonCell *deleteButtonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [deleteButtonCell useSecondaryRed];
    deleteButtonCell.delegate = self;
    [deleteButtonCell setAction:@"delete"];
    [deleteButtonCell setButtonLabel:@"Delete"];
    [_cellArray addObject:deleteButtonCell];
    
    [_tableView reloadData];
    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    self.mode = MCPointViewModeDisplay;
    // TODO add empty state
}


/**
    Take the contents of the queried feature row and show the appropriate edit control and keyboard type based on the datatype of the database column.
 */
- (void)showEditMode {
    _cellArray = [[NSMutableArray alloc] init];
    
    MCLayerCell *details = [self.tableView dequeueReusableCellWithIdentifier:@"layerCell"];
    [details setName:self.databaseName];
    [details setDetails:self.layerName];
    [details activeIndicatorOff];
    [details.layerTypeImage setImage:[UIImage imageNamed:@"Point"]];
    [_cellArray addObject:details];
    
    _attachmentButtonsCell = [self.tableView dequeueReusableCellWithIdentifier:@"buttons"];
    [_attachmentButtonsCell setLeftButtonLabel:@""];
    [_attachmentButtonsCell setLeftButtonAction:@"camera"];
    [_attachmentButtonsCell leftButtonUseClearBackground];
    [_attachmentButtonsCell.leftButton setImage:[UIImage imageNamed:@"camera"] forState:UIControlStateNormal];
    [_attachmentButtonsCell setRightButtonLabel:@""];
    [_attachmentButtonsCell setRightButtonAction:@"photos"];
    [_attachmentButtonsCell rightButtonUseClearBackground];
    [_attachmentButtonsCell.rightButton setImage:[UIImage imageNamed:@"gallery"] forState:UIControlStateNormal];
    _attachmentButtonsCell.dualButtonDelegate = self;
    [_cellArray addObject:_attachmentButtonsCell];
    
    if (self.media.count > 0 || self.addedMedia.count > 0) {
        self.attachmentsCell = [self.tableView dequeueReusableCellWithIdentifier:@"attachmentsCell"];
        self.attachmentsCell.attachmentDelegate = self.showAttachmentDelegate;
        NSMutableArray *allMedia = [[NSMutableArray alloc] initWithArray:self.media];
        [allMedia addObjectsFromArray:self.addedMedia];
        [self.attachmentsCell setContentsWithMediaArray:allMedia];
        [self.attachmentsCell.collectionView reloadData];
        [self.cellArray addObject:self.attachmentsCell];
    }
    
    if (_row.columnCount == 2) { // no user editable columns
        MCDescriptionCell *empty = [self.tableView dequeueReusableCellWithIdentifier:@"descriptionDisplay"];
        [empty setDescription:@"This layer has no fields."];
        [_cellArray addObject:empty];
        
        MCButtonCell *addFieldsButtonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
        [addFieldsButtonCell useSecondaryColors];
        addFieldsButtonCell.delegate = self;
        [addFieldsButtonCell setAction:@"addFields"];
        [addFieldsButtonCell setButtonLabel:@"Add fields"];
        [_cellArray addObject:addFieldsButtonCell];
    }
    
    if (_row) {
        NSString *idColumnName = [_row idColumnName]; // the Primary Key column name
        NSString *geometryColumnName = [(GPKGFeatureRow*)_row geometryColumnName];
        
        for (int i = 0; i < _row.columnCount; i++) {
            NSString *columnName = _row.columnNames[i];
            enum GPKGDataType dataType = _row.columns.columns[i].dataType;
            
            if (![columnName isEqualToString:idColumnName] && ![columnName isEqualToString:@"id"] && ![columnName isEqualToString:geometryColumnName]) {
                MCFieldWithTitleCell *fieldWithTitle = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
                [fieldWithTitle setTitleText:columnName];
                fieldWithTitle.columnName = columnName;
                fieldWithTitle.dataType = dataType;
                [fieldWithTitle setTextFieldDelegate:self];
                
                if (_row.columns.columns[i].dataType == GPKG_DT_TEXT) {
                    if (![_row.values[i] isKindOfClass:NSNull.class]) {
                        [fieldWithTitle setFieldText:_row.values[i]];
                    }
                    
                    [fieldWithTitle useReturnKeyDone];
                    [_cellArray addObject:fieldWithTitle];
                } else if (dataType == GPKG_DT_INTEGER || dataType == GPKG_DT_REAL || dataType == GPKG_DT_DOUBLE || dataType == GPKG_DT_INT || dataType == GPKG_DT_FLOAT || dataType == GPKG_DT_SMALLINT || dataType == GPKG_DT_TINYINT || dataType == GPKG_DT_MEDIUMINT) {
                    if (![_row.values[i] isKindOfClass:NSNull.class] && _row.values[i] != nil) {
                        if ([_row.values[i] respondsToSelector:@selector(stringValue)]) {
                            [fieldWithTitle setFieldText:[_row.values[i] stringValue]];
                        }
                    }
                    [fieldWithTitle setupNumericalKeyboard];
                    [_cellArray addObject:fieldWithTitle];
                } else if (dataType == GPKG_DT_BOOLEAN) {
                    MCSwitchCell *switchCell = [self.tableView dequeueReusableCellWithIdentifier:@"switchCell"];
                    [switchCell.label setText:columnName];
                    switchCell.columnName = columnName;
                    switchCell.switchDelegate = self;

                    if ([_row.values[i] isKindOfClass:NSNull.class] || _row.values[i] == nil || [_row.values[i] boolValue] == NO) {
                        [switchCell switchOff];
                    } else {
                        [switchCell switchOn];
                    }
                    
                    [_cellArray addObject:switchCell];
                }
            }
        }
    }
    _buttonsCell = [self.tableView dequeueReusableCellWithIdentifier:@"buttons"];
    [_buttonsCell setLeftButtonLabel:@"Cancel"];
    [_buttonsCell setLeftButtonAction:@"cancel"];
    [_buttonsCell leftButtonUseSecondaryColors];
    
    [_buttonsCell setRightButtonLabel:@"Save"];
    [_buttonsCell setRightButtonAction:@"save"];
    [_buttonsCell rightButtonUsePrimaryColors];
    _buttonsCell.dualButtonDelegate = self;
    [_cellArray addObject:_buttonsCell];
    
    MCEmptyStateCell *spacer = [self.tableView dequeueReusableCellWithIdentifier:@"spacer"];
    [spacer useAsSpacer];
    [_cellArray addObject:spacer];
    
    [_tableView reloadData];
    //[_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
    [_tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
    self.mode = MCPointViewModeEdit;
}


- (void)reloadWith:(GPKGUserRow *)row mapPoint:(GPKGMapPoint *)mapPoint mode:(MCMapPointViewMode)mode {
    self.row = row;
    self.mapPoint = mapPoint;
    
    if (mode == MCPointViewModeDisplay) {
        [self showDisplayMode];
    } else if (mode == MCPointViewModeEdit) {
        [self showEditMode];
    }
}


#pragma mark - UITableViewDelegate methods
- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *) indexPath {
    return [self.cellArray objectAtIndex:indexPath.row];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
     [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
}


-(NSInteger) numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}


- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.cellArray count];
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewAutomaticDimension;
}


- (BOOL)gestureIsInConflict:(UIPanGestureRecognizer *) recognizer {
    CGPoint point = [recognizer locationInView:self.view];
    
    if (CGRectContainsPoint(self.attachmentsCell.frame, point)) {
        return true;
    }
    
    return false;
}

#pragma mark- UITextFieldDelegate methods
- (void) textFieldDidBeginEditing:(UITextField *)textField {
    UITableViewCell *cell = (UITableViewCell *)[textField superview];
    [_tableView scrollToRowAtIndexPath:[_tableView indexPathForCell:cell] atScrollPosition:UITableViewScrollPositionTop animated:YES];
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
    MCFieldWithTitleCell *fieldWithTitleCell = (MCFieldWithTitleCell *)[textField superview];
    [fieldWithTitleCell.field trimWhiteSpace];
    
    BOOL inputIsValid = [fieldWithTitleCell.field fieldValueValidForType:fieldWithTitleCell.dataType];
    if (!inputIsValid) {
        [fieldWithTitleCell useErrorAppearance];
        [_buttonsCell disableRightButton];
    } else {
        [fieldWithTitleCell useNormalAppearance];
        [_buttonsCell enableRightButton];
    }
    
    [self.row setValueWithColumnName:fieldWithTitleCell.columnName andValue: [fieldWithTitleCell fieldValue]];
}


- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - MCDualButtonCellDelegate methods
- (void)performDualButtonAction:(NSString *)action {
    if ([action isEqualToString:@"camera"]) {
        _imagePicker.allowsEditing = NO;
        _imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
        _imagePicker.cameraCaptureMode = UIImagePickerControllerCameraCaptureModePhoto;
        _imagePicker.modalPresentationStyle = UIModalPresentationFullScreen;
        [self presentViewController:_imagePicker animated:YES completion:nil];
    } else if ([action isEqualToString:@"photos"]) {
        _imagePicker.allowsEditing = NO;
        _imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:_imagePicker animated:YES completion:nil];
    } else if ([action isEqualToString:@"save"]) {
        NSLog(@"Saving point data");
        BOOL saved = [_mapPointDataDelegate saveRow:_row attachments:self.addedMedia databaseName:self.databaseName];
        
        if (saved) {
            self.addedMedia = [[NSMutableArray alloc] init];
            [self showDisplayMode];
        }
    } else if ([action isEqualToString:@"edit"]) {
        // TODO Add switch to edit mode
        NSLog(@"Editing point");
        
        if (self.mode != MCPointViewModeEdit) {
            [self showEditMode];
        } else {
            [self showDisplayMode];
        }
    } else if ([action isEqualToString:@"cancel"]) {
        NSLog(@"Canceling point edit");
        
        if (self.mapPoint.data == nil) { // the point is new, close out the view
            [self.drawerViewDelegate popDrawer];
            [self.mapPointDataDelegate mapPointDataViewClosedWithNewPoint:YES];
        } else {
            [self showDisplayMode];
        }
    }
}


- (void)performButtonAction:(NSString *)action {
    if ([action isEqualToString:@"edit"]) {
        // TODO Add switch to edit mode
        NSLog(@"Editing point");
        
        if (self.mode != MCPointViewModeEdit) {
            [self showEditMode];
        } else {
            [self showDisplayMode];
        }
    } else if ([action isEqualToString:@"delete"]) {
        UIAlertController *deleteAlert = [UIAlertController alertControllerWithTitle:@"Delete" message:@"Do you want to delete this point? This action can not be undone." preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *confirmDelete = [UIAlertAction actionWithTitle:@"Delete" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
            NSString *databaseName = [self.mapPoint.data valueForKey:@"database"];
            [self.mapPointDataDelegate deleteRow:self.row fromDatabase:databaseName andRemoveMapPoint:self.mapPoint];
        }];
        
        UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [deleteAlert dismissViewControllerAnimated:YES completion:nil];
        }];
        
        [deleteAlert addAction:confirmDelete];
        [deleteAlert addAction:cancel];
        
        [self presentViewController:deleteAlert animated:YES completion:nil];
    } else if ([action isEqualToString:@"addFields"]) {
        [self.mapPointDataDelegate showFieldEditor];
    }
}


#pragma mark - MCSwitchCellDelegate methods
- (void) switchChanged:(id) sender {
    UISwitch *switchControl = (UISwitch*)sender;
    
    MCSwitchCell *switchCell = (MCSwitchCell *)[sender superview];
    NSNumber *isOn = [switchControl isOn] ? [NSNumber numberWithInt:1] : [NSNumber numberWithInt:0];
    [self.row setValueWithColumnName:switchCell.columnName andValue:isOn];
}


#pragma mark - NGADrawerView methods
- (void) closeDrawer {
    BOOL haveNewPoint = _mapPoint.data == nil;
    self.addedMedia = [[NSMutableArray alloc] init];
    [self.drawerViewDelegate popDrawer];
    [self.mapPointDataDelegate mapPointDataViewClosedWithNewPoint:haveNewPoint];
}


// Override this method to make the drawer and the scrollview play nice
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.haveScrolled) {
        [self rollUpPanGesture:scrollView.panGestureRecognizer withScrollView:scrollView];
    }
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.haveScrolled = YES;
    
    if (!self.isFullView) {
        scrollView.scrollEnabled = NO;
        scrollView.scrollEnabled = YES;
    } else {
        scrollView.scrollEnabled = YES;
    }
}


#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey,id> *)info {
    UIImage *chosenImage = (UIImage *)[info objectForKey:UIImagePickerControllerOriginalImage];
    //[self.media addObject:chosenImage];
    [self.addedMedia addObject:chosenImage];
    [self showEditMode];
    [picker dismissViewControllerAnimated:YES completion:nil];
}


- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}


@end
