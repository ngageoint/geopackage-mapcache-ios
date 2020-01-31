//
//  GPKGSTileLayerDetailsViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/9/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCTileLayerDetailsViewController.h"

@interface MCTileLayerDetailsViewController ()
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) MCButtonCell *buttonCell;
@property (nonatomic, strong) MCButtonCell *selectServerButtonCell;
@property (nonatomic, strong) MCButtonCell *helpButtonCell;
@property (nonatomic, strong) MCFieldWithTitleCell *layerNameCell;
@property (nonatomic, strong) MCFieldWithTitleCell *urlCell;
@property (nonatomic, strong) UITableView *tableView;
@end

@implementation MCTileLayerDetailsViewController

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
    self.selectedServerURL = nil;
    self.layerName = nil;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) initCellArray {
    _cellArray = [[NSMutableArray alloc] init];
    
    MCTitleCell *title = [self.tableView dequeueReusableCellWithIdentifier:@"title"];
    title.label.text = @"New tile layer";
    [_cellArray addObject:title];
    
    _layerNameCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _layerNameCell.title.text = @"Layer name";
    
    if (self.layerName != nil) {
        [_layerNameCell.field setText:self.layerName];
    }
    
    [_layerNameCell.field setReturnKeyType:UIReturnKeyDone]; // TODO look into UIReturnKeyNext
    _layerNameCell.field.delegate = self;
    [_cellArray addObject:_layerNameCell];
    
    _urlCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    [_urlCell setTitleText:@"Tile server URL"];
    
    if (self.selectedServerURL != nil) {
        [_urlCell setFieldText:self.selectedServerURL];
    } else {
        [_urlCell setPlaceholder:@"https://osm.gs.mil/tiles/default/{x}/{y}/{z}.png"];
        [_urlCell setFieldText:@"https://osm.gs.mil/tiles/default/{z}/{x}/{y}.png"];
    }
    
    [_urlCell setTextFielDelegate: self];
    [_urlCell useReturnKeyDone];
    [_cellArray addObject:_urlCell];
    
    MCDescriptionCell *urlDescription = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    urlDescription.descriptionLabel.text = @"Tip: XYZ and WMS are supported. Make sure you enter the URL template.";
    [_cellArray addObject:urlDescription];
    
    _selectServerButtonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [_selectServerButtonCell.button setTitle:@"Choose Tile Server" forState:UIControlStateNormal];
    _selectServerButtonCell.action = @"ShowServers";
    _selectServerButtonCell.delegate = self;
    [_cellArray addObject:_selectServerButtonCell];
    [_selectServerButtonCell useSecondaryColors];
    
    _buttonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [_buttonCell.button setTitle:@"Next" forState:UIControlStateNormal];
    [_buttonCell disableButton];
    _buttonCell.delegate = self;
    _buttonCell.action = @"ContinueToBoundingBox";
    [_cellArray addObject:_buttonCell];
    
    _helpButtonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [_helpButtonCell.button setTitle:@"More about URL templates" forState:UIControlStateNormal];
    _helpButtonCell.action = @"ShowHelp";
    _helpButtonCell.delegate = self;
    [_cellArray addObject:_helpButtonCell];
    [_helpButtonCell useSecondaryColors];
}

- (void)update {
    [self initCellArray];
    [self.tableView reloadData];
    [self textFieldDidEndEditing:self.layerNameCell.field];
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCFieldWithTitleCell" bundle:nil] forCellReuseIdentifier:@"fieldWithTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
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
    [textField trimWhiteSpace:textField];
    
    if (textField == _urlCell.field) {
        NSLog(@"URL Field ended editing");
        [textField isValidTileServerURL:textField withResult:^(BOOL isValid) {
            if (isValid) {
                NSLog(@"Valid URL");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.urlCell useNormalAppearance];
                    [self.buttonCell enableButton];
                });
            } else {
                NSLog(@"Bad url");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.buttonCell disableButton];
                    [self.urlCell useErrorAppearance];
                });
            }
        }];
    } else {
        self.layerName = textField.text;
        BOOL isLayerNameAvailable = [self.delegate isLayerNameAvailable: self.layerName];
        
        if ([_layerNameCell.field.text isEqualToString:@""] || !isLayerNameAvailable) {
            [self.layerNameCell useErrorAppearance];
            [_buttonCell disableButton];
        } else {
            [self.layerNameCell useNormalAppearance];
            [_buttonCell enableButton];
        }
    }
    
    [textField resignFirstResponder];
}


- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - GPKGSButtonCellDelegate methods
- (void) performButtonAction:(NSString *)action {
    if ([action isEqualToString:@"ContinueToBoundingBox"]) {
        [_delegate tileLayerDetailsCompletionHandlerWithName:_layerNameCell.field.text URL:_urlCell.field.text andReferenceSystemCode:PROJ_EPSG_WEB_MERCATOR];
    } else if ([action isEqualToString:@"ShowServers"]) {
        [self.delegate showTileServerList];
    } else {
        [_delegate showURLHelp];
    }
}

#pragma mark - NGADrawerView methods
- (void) closeDrawer {
    [self.drawerViewDelegate popDrawer];
}

- (BOOL)gestureIsInConflict:(UIPanGestureRecognizer *) recognizer {
    CGPoint point = [recognizer locationInView:self.view];
    
    if (CGRectContainsPoint(_layerNameCell.frame, point) || CGRectContainsPoint(_urlCell.frame, point)) {
        return true;
    }
    
    return false;
}

@end
