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
    
    MCDesctiptionCell *tilesDescription = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    tilesDescription.descriptionLabel.text = @"Tile layers consist of a pyramid of images within a geographic extent and zoom levels.";
    [_cellArray addObject:tilesDescription];
    
    _layerNameCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _layerNameCell.title.text = @"New layer name";
    [_layerNameCell.field setReturnKeyType:UIReturnKeyDone]; // TODO look into UIReturnKeyNext
    _layerNameCell.field.delegate = self;
    [_cellArray addObject:_layerNameCell];
    
    
    _urlCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _urlCell.title.text = @"Tile server URL";
    _urlCell.field.placeholder = @"https://osm.gs.mil/tiles/default/{x}/{y}/{z}.png";
    _urlCell.field.text = @"https://osm.gs.mil/tiles/default/{z}/{x}/{y}.png";
    _urlCell.field.delegate = self;
    [_urlCell.field setReturnKeyType:UIReturnKeyDone];
    [_cellArray addObject:_urlCell];
    
    MCDesctiptionCell *urlDescription = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    urlDescription.descriptionLabel.text = @"Tip: Make sure you enter the full URL to the tile server with the {x}/{y}/{z}.png template on the end.";
    [_cellArray addObject:urlDescription];
    
    _buttonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [_buttonCell.button setTitle:@"Next" forState:UIControlStateNormal];
    [_buttonCell disableButton];
    _buttonCell.delegate = self;
    _buttonCell.action = @"BoundingBox";
    [_cellArray addObject:_buttonCell];
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
                    self.urlCell.field.borderStyle = UITextBorderStyleRoundedRect;
                    self.urlCell.field.layer.cornerRadius = 4;
                    self.urlCell.field.layer.borderColor = [[UIColor colorWithRed:0.79 green:0.8 blue:0.8 alpha:1] CGColor];
                    self.urlCell.field.layer.borderWidth = 0.5;
                    [self.buttonCell enableButton];
                });
            } else {
                NSLog(@"Bad url");
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.buttonCell disableButton];
                    self.urlCell.field.borderStyle = UITextBorderStyleRoundedRect;
                    self.urlCell.field.layer.cornerRadius = 4;
                    self.urlCell.field.layer.borderColor = [[UIColor redColor] CGColor];
                    self.urlCell.field.layer.borderWidth = 2.0;
                });
            }
        }];
    } else {
        if ([_layerNameCell.field.text isEqualToString:@""] || [_urlCell.field.text isEqualToString:@""]) {
            [_buttonCell disableButton];
        } else {
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
    [_delegate tileLayerDetailsCompletionHandlerWithName:_layerNameCell.field.text URL:_urlCell.field.text andReferenceSystemCode:3857];
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
