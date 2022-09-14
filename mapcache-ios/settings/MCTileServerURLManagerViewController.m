//
//  MCTileServerURLManagerViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/22/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "MCTileServerURLManagerViewController.h"
#import "mapcache_ios-Swift.h"


@interface MCTileServerURLManagerViewController ()
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) MCButtonCell *buttonCell;
@property (nonatomic, strong) MCFieldWithTitleCell *urlCell;
@property (nonatomic, strong) NSDictionary *tileServers;
@end

@implementation MCTileServerURLManagerViewController

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
    self.tableView.backgroundColor = [UIColor colorNamed:@"ngaBackgroundColor"];
    [self registerCellTypes];
    [self initCellArray];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;

    UIEdgeInsets tabBarInsets = UIEdgeInsetsMake(0, 0, self.tabBarController.tabBar.frame.size.height, 0);
    self.tableView.contentInset = tabBarInsets;
    self.tableView.scrollIndicatorInsets = tabBarInsets;
    [self.view addSubview:self.tableView];
//    [self addDragHandle];
//    [self addCloseButton];
    self.selectMode = NO;
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self initCellArray];
    [self.tableView reloadData];
}


- (void) initCellArray {
    self.cellArray = [[NSMutableArray alloc] init];
    
    MCTitleCell *tileTitle = [self.tableView dequeueReusableCellWithIdentifier:@"title"];
    [tileTitle.label setText:@"Tile Server URLs"];
    [self.cellArray addObject:tileTitle];
     
    MCDescriptionCell *description = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    [description.descriptionLabel setText:@"Saved URLs for easy access when creating new tile layers."];
    [self.cellArray addObject:description];
    
    self.buttonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [self.buttonCell setButtonLabel:@"New Tile Server"];
    [self.buttonCell setAction:@"SAVE"];
    [self.buttonCell setDelegate:self];
    [self.cellArray addObject:self.buttonCell];
    
    
    MCTileServer *defaultServer = [[MCTileServer alloc] init];
    [defaultServer setServerName:@"GEOINT Services OSM"];
    [defaultServer setUrl:@"https://osm.gs.mil/tiles/default/{z}/{x}/{y}.png"];
    [defaultServer setServerType: MCTileServerTypeXyz];
    MCTileServerCell *tileServerCell = [self.tableView dequeueReusableCellWithIdentifier:@"server"];
    [tileServerCell setContentWithTileServer:defaultServer];
    [tileServerCell activeIndicatorOff];
    [self.cellArray addObject:tileServerCell];
    
    self.tileServers = [[MCTileServerRepository shared] getTileServers];
    
    if (self.tileServers) {
        NSArray *serverNames = [self.tileServers allKeys];
        for (NSString *serverName in serverNames) {
            MCTileServer *tileServer = [self.tileServers objectForKey:serverName];
            MCTileServerCell *tileServerCell = [self.tableView dequeueReusableCellWithIdentifier:@"server"];
            [tileServerCell setContentWithTileServer:tileServer];
            [tileServerCell activeIndicatorOff];
            
            if (tileServer.serverType == MCTileServerTypeAuthRequired) {
                [tileServerCell.icon setImage:[UIImage imageNamed:[MCProperties getValueOfProperty:MC_PROP_ICON_TILE_SERVER_LOGIN]]];
                [tileServerCell setLayersLabelText:@"Tap to login"];
            }
            
            [self.cellArray addObject:tileServerCell];
        }
    }
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCFieldWithTitleCell" bundle:nil] forCellReuseIdentifier:@"fieldWithTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTileServerCell" bundle:nil] forCellReuseIdentifier:@"server"];
}


- (void) update {
    [self initCellArray];
    [self.tableView reloadData];
}


- (void)addAndConstrainSubview:(UIView *) view {
    [self.view addSubview:view];
    
    NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:0];
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    
    
    [[view.topAnchor constraintEqualToAnchor:self.view.topAnchor] setActive:YES];
    [[view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor] setActive:YES];
    [[view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor] setActive:YES];
    [[view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor] setActive:YES];
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    
    view.frame = self.view.frame;
    
    [self.view addConstraints:@[left, top, right, bottom]];
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


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self.tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    if (self.selectMode && [[_cellArray objectAtIndex:indexPath.row] isKindOfClass: MCTileServerCell.class]) {
        MCTileServerCell *cell = [self.cellArray objectAtIndex:indexPath.row];
        MCTileServer *tileServer = cell.tileServer;
        
        if (tileServer.serverType == MCTileServerTypeWms || tileServer.serverType == MCTileServerTypeXyz || tileServer.serverType == MCTileServerTypeAuthRequired) {
            [self.selectServerDelegate selectTileServer:tileServer];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[_cellArray objectAtIndex:indexPath.row] isKindOfClass:[MCLayerCell class]]) {
        MCLayerCell *cell = [self.cellArray objectAtIndex:indexPath.row];
        
        if ([cell.layerNameLabel.text isEqualToString:@"GEOINT Services OSM"]) {
            return NO;
        } else {
            return YES;
        }
    } else {
        return NO;
    }
}


- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UIContextualAction *editAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Edit" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        MCLayerCell *cell = [self.cellArray objectAtIndex:indexPath.row];
        [self.tileServerManagerDelegate editTileServer:cell.layerNameLabel.text];
        completionHandler(YES);
    }];
    
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        MCLayerCell *cell = [self.cellArray objectAtIndex:indexPath.row];
        [self.tileServerManagerDelegate deleteTileServer: cell.layerNameLabel.text];
        completionHandler(YES);
    }];
    
    editAction.backgroundColor = [UIColor purpleColor];
    deleteAction.backgroundColor = [UIColor redColor];
    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:@[editAction, deleteAction]];
    configuration.performsFirstActionWithFullSwipe = YES;
    return configuration;
}


- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


#pragma mark - NGADrawerView methods
//- (void) closeDrawer {
//    [self.drawerViewDelegate popDrawer];
//}


#pragma mark - GPKGSButtonCellDelegate methods
- (void) performButtonAction:(NSString *)action {
    [self.tileServerManagerDelegate showNewTileServerView];
}


@end
