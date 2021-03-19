//
//  MCSettingsViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/5/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCSettingsViewController.h"
#import "mapcache_ios-Swift.h"

NSString *const SHOW_NOTICE = @"showNotice";
NSString *const SHOW_TILE_URL_MANAGER =@"showTileURLManager";

@interface MCSettingsViewController ()
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) MCSegmentedControlCell *baseMapSelector;
@property (nonatomic, strong) MCFieldWithTitleCell *maxFeaturesCell;
@property (nonatomic, strong) MCSwitchCell *alertSwitchCell;
@property (nonatomic, strong) MCSwitchCell *zoomSwitchCell;
@property (nonatomic, strong) NSUserDefaults *settings;
@property (nonatomic) BOOL haveScrolled;
@property (nonatomic, strong) NSDictionary *savedTileServers;
@property (nonatomic, strong) MCTileServer *expandedServer;
@end

@implementation MCSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.haveScrolled = NO;
    self.tableView = [[UITableView alloc] init];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 390.0;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    self.savedTileServers = [[MCTileServerRepository shared] getTileServers];
    [self registerCellTypes];
    [self initCellArray];
    [self addAndConstrainSubview:self.tableView];
    
    [self addDragHandle];
    [self addCloseButton];
    
}


- (void) update {
    self.savedTileServers = [[MCTileServerRepository shared] getTileServers];
    [self initCellArray];
    [self.tableView reloadData];
}


- (void) closeDrawer {
    [super closeDrawer];
    [_mapSettingsDelegate settingsCompletionHandler];
    [self.drawerViewDelegate popDrawer];
}


- (void)initCellArray {
    _cellArray = [[NSMutableArray alloc] init];
    
    MCTitleCell *titleCell = [_tableView dequeueReusableCellWithIdentifier:@"title"];
    titleCell.label.text = @"Settings";
    
    
    self.settings = [NSUserDefaults standardUserDefaults];
    _baseMapSelector = [_tableView dequeueReusableCellWithIdentifier:@"segmentedControl"];
    _baseMapSelector.label.text = @"Base Map Type";
    _baseMapSelector.delegate = self;
    NSArray *maps = [[NSArray alloc] initWithObjects: [MCProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_STANDARD],
                     [MCProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_SATELLITE],
                     [MCProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_HYBRID], nil];
    [_baseMapSelector updateItems:maps];
    
    NSString *mapType = [self.settings stringForKey:GPKGS_PROP_MAP_TYPE];
    if (mapType == nil || [mapType isEqualToString:[MCProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_STANDARD]]) {
        [_baseMapSelector.segmentedControl setSelectedSegmentIndex:0];
    } else if ([mapType isEqualToString:[MCProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_SATELLITE]]) {
        [_baseMapSelector.segmentedControl setSelectedSegmentIndex:1];
    } else {
        [_baseMapSelector.segmentedControl setSelectedSegmentIndex:2];
    }
    
    NSArray *topCells = @[titleCell, _baseMapSelector];
    [_cellArray addObject:topCells];
    
    MCTileServer *defaultServer = [[MCTileServer alloc] initWithServerName:@"GEOINT Services OSM"];
    defaultServer.url = @"https://osm.gs.mil/tiles/default/{z}/{x}/{y}.png";
    defaultServer.serverType = MCTileServerTypeXyz;
    MCTileServerCell *defaultServerCell = [self.tableView dequeueReusableCellWithIdentifier:@"tileServerCell"];
    [defaultServerCell setContentWithTileServer:defaultServer];
    
    if (self.basemapTileServer.serverName == defaultServer.serverName) {
        [defaultServerCell activeIndicatorOn];
    } else {
        [defaultServerCell activeIndicatorOff];
    }
    
    NSMutableArray *serverCells = [[NSMutableArray alloc] init];
    [serverCells addObject:defaultServerCell];
    
    if (self.savedTileServers) {
        NSArray *serverNames = [self.savedTileServers allKeys];
        for (NSString *serverName in serverNames) {
            MCTileServer *tileServer = [self.savedTileServers objectForKey:serverName];
            MCTileServerCell *tileServerCell = [self.tableView dequeueReusableCellWithIdentifier:@"tileServerCell"];
            [tileServerCell setContentWithTileServer:tileServer];
                        
            NSMutableArray *wmsLayers = [[NSMutableArray alloc] init];
            
            if (tileServer.serverType == MCTileServerTypeWms) {
                NSString *layerLabel = tileServer.layers.count == 1? @"layer" : @"layers";
                NSString *details = [NSString stringWithFormat:@"%lu %@", (unsigned long)tileServer.layers.count, layerLabel];
                [tileServerCell setLayersLabelText:details];
                
                if (self.basemapTileServer.serverName == tileServer.serverName) {
                    [tileServerCell activeIndicatorOn];
                }
                
                if ([self.expandedServer.serverName isEqualToString:tileServer.serverName]) {
                    for (MCLayer *layer in tileServer.layers) {
                        MCLayerCell *layerCell = [self.tableView dequeueReusableCellWithIdentifier:@"layerCell"];
                        [layerCell setContentsWithLayer:layer tileServer:tileServer];
                        
                        if (self.basemapTileServer.serverName == tileServer.serverName && self.basemapLayer.name == layer.name) {
                            [layerCell activeIndicatorOn];
                        }
                        
                        [wmsLayers addObject:layerCell];
                    }
                }
            }
            
            if (tileServer.serverType == MCTileServerTypeError) {
                [tileServerCell.icon setImage:[UIImage imageNamed:[MCProperties getValueOfProperty:MC_PROP_ICON_TILE_SERVER_ERROR]]];
                [tileServerCell setLayersLabelText:@"Unable to reach server"];
            } else {
                [tileServerCell.icon setImage:[UIImage imageNamed:[MCProperties getValueOfProperty:GPKGS_PROP_ICON_TILE_SERVER]]];
            }
            
            [tileServerCell activeIndicatorOff];
            [serverCells addObject:tileServerCell];
            [serverCells addObjectsFromArray:wmsLayers];
        }
    }
    
    [self.cellArray addObject:serverCells];
    
    NSMutableArray *bottomCells = [[NSMutableArray alloc] init];
    
    MCButtonCell *tileURLServerManagerButtonCell = [self.tableView dequeueReusableCellWithIdentifier:@"buttonCell"];
    [tileURLServerManagerButtonCell setButtonLabel:@"New Tile Server"];
    tileURLServerManagerButtonCell.action = SHOW_TILE_URL_MANAGER;
    tileURLServerManagerButtonCell.delegate = self;
    [bottomCells addObject:tileURLServerManagerButtonCell];
    
    _maxFeaturesCell = [_tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _maxFeaturesCell.title.text = @"Maximum number of features";
    int maxFeatures = (int)[self.settings integerForKey:GPKGS_PROP_MAP_MAX_FEATURES];
    if(maxFeatures == 0){
        maxFeatures = [[MCProperties getNumberValueOfProperty:GPKGS_PROP_MAP_MAX_FEATURES_DEFAULT] intValue];
    }
    _maxFeaturesCell.field.text = [NSString stringWithFormat:@"%d", maxFeatures];
    [_maxFeaturesCell setTextFielDelegate:self];
    [_maxFeaturesCell setupNumericalKeyboard];
    [bottomCells addObject:_maxFeaturesCell];
    
    _alertSwitchCell = [_tableView dequeueReusableCellWithIdentifier:@"switchCell"];
    _alertSwitchCell.label.text = @"Max feature warning";
    _alertSwitchCell.switchDelegate = self;
    BOOL hideWarning = [self.settings boolForKey:GPKGS_PROP_HIDE_MAX_FEATURES_WARNING];
    if (hideWarning) {
        [_alertSwitchCell switchOn];
    } else {
        [_alertSwitchCell switchOff];
    }
    [bottomCells addObject:_alertSwitchCell];
    
    _zoomSwitchCell = [_tableView dequeueReusableCellWithIdentifier:@"switchCell"];
    _zoomSwitchCell.label.text = @"Zoom level indicator";
    _zoomSwitchCell.switchDelegate = self;
    BOOL hideZoomIndicator = [self.settings boolForKey:GPKGS_PROP_HIDE_ZOOM_LEVEL_INDICATOR];
    if (hideZoomIndicator) {
        [_zoomSwitchCell switchOff];
    } else {
        [_zoomSwitchCell switchOn];
    }
    [bottomCells addObject:_zoomSwitchCell];
    
    MCButtonCell *showNoticesButtonCell = [self.tableView dequeueReusableCellWithIdentifier:@"buttonCell"];
    [showNoticesButtonCell setButtonLabel:@"About MapCache"];
    showNoticesButtonCell.action = SHOW_NOTICE;
    showNoticesButtonCell.delegate = self;
    [showNoticesButtonCell useSecondaryColors];
    [bottomCells addObject:showNoticesButtonCell];
    [_cellArray addObject:bottomCells];
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCSectionTitleCell" bundle:nil] forCellReuseIdentifier:@"sectionTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCSegmentedControlCell" bundle:nil] forCellReuseIdentifier:@"segmentedControl"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCFieldWithTitleCell" bundle:nil] forCellReuseIdentifier:@"fieldWithTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCSwitchCell" bundle:nil] forCellReuseIdentifier:@"switchCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCButtonCell" bundle:nil] forCellReuseIdentifier:@"buttonCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCLayerCell" bundle:nil] forCellReuseIdentifier:@"layerCell"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTileServerCell" bundle:nil] forCellReuseIdentifier:@"tileServerCell"];
}


#pragma mark - TableView delegate methods
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [[_cellArray objectAtIndex:indexPath.section] objectAtIndex:indexPath.row];
}
    

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSArray *cells = [_cellArray objectAtIndex:section];
    return [cells count];
}


- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [_cellArray count];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    NSArray *cells = [_cellArray objectAtIndex:indexPath.section];
    
    if ([[cells objectAtIndex:indexPath.row] isKindOfClass:MCTileServerCell.class]) {
        MCTileServerCell *cell = (MCTileServerCell *)[cells objectAtIndex:indexPath.row];
        MCTileServer *tappedServer = cell.tileServer;
        
        if (tappedServer.serverType == MCTileServerTypeWms) {
            if (self.expandedServer == nil) {
                self.expandedServer = tappedServer;
                [self initCellArray];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
            } else if (self.expandedServer != nil) {
                if ([tappedServer.serverName isEqualToString:self.expandedServer.serverName]) {
                    self.expandedServer = nil;
                } else {
                    self.expandedServer = tappedServer;
                }
                
                [self initCellArray];
                [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
            }
        }
    }
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


// Choose which types of cells can have swipe actions
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *cells = [_cellArray objectAtIndex:indexPath.section];
    
    if ([[cells objectAtIndex:indexPath.row] isKindOfClass:[MCLayerCell class]] || [[cells objectAtIndex:indexPath.row] isKindOfClass:MCTileServerCell.class]) {
        return YES;
    }
      
    return NO;
}


- (UISwipeActionsConfiguration *) tableView:(UITableView *)tableView leadingSwipeActionsConfigurationForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    MCLayerCell *layerCell = nil;
    MCTileServerCell *tileServerCell = nil;
    NSArray *cells = [_cellArray objectAtIndex:indexPath.section];
    
    if ([[cells objectAtIndex:indexPath.row] isKindOfClass:MCTileServerCell.class]) {
        tileServerCell = (MCTileServerCell *)[cells objectAtIndex:indexPath.row];
    } else if ([[cells objectAtIndex:indexPath.row] isKindOfClass:MCLayerCell.class]) {
        layerCell = (MCLayerCell *)[cells objectAtIndex:indexPath.row];
    }
    
    if (tileServerCell != nil && tileServerCell.tileServer.serverType == MCTileServerTypeWms) {
        UISwipeActionsConfiguration *emptyConfiguration = [UISwipeActionsConfiguration configurationWithActions:@[]];
        return emptyConfiguration;
    }
    
    UIContextualAction *toggleAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Add to map" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        
        if (tileServerCell != nil) {
            if (tileServerCell.tileServer.serverType == MCTileServerTypeXyz) {
                if ([tileServerCell.visibilityStatusIndicator isHidden]) {
                    toggleAction.backgroundColor = [UIColor colorWithRed:0.13 green:0.31 blue:0.48 alpha:1.0];
                    toggleAction.title = @"Use as basemap";
                    
                    [self.settingsDelegate setUserBasemap:tileServerCell.tileServer layer:[[MCLayer alloc] init]];
                } else {
                    toggleAction.backgroundColor = [UIColor grayColor];
                    toggleAction.title = @"Remove basemap";
                    [self.settingsDelegate setUserBasemap:nil layer:nil];
                }
            }
            
            [tileServerCell toggleActiveIndicator];
        } else if (layerCell != nil) {
            if ([layerCell.activeIndicator isHidden]) {
                toggleAction.backgroundColor = [UIColor colorWithRed:0.13 green:0.31 blue:0.48 alpha:1.0];
                toggleAction.title = @"Use as basemap";
                [_settingsDelegate setUserBasemap:layerCell.tileServer layer:layerCell.mapLayer];
            } else {
                toggleAction.backgroundColor = [UIColor grayColor];
                toggleAction.title = @"Remove basemap";
                [self.settingsDelegate setUserBasemap:nil layer:nil];
            }
            
            [layerCell toggleActiveIndicator];
        }
        
        completionHandler(YES);
    }];
    
    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:@[toggleAction]];
    configuration.performsFirstActionWithFullSwipe = YES;
    return configuration;
}


- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    // if the server is the default NGA OSM server, dont let them edit or delete it
    MCLayerCell *layerCell = nil;
    MCTileServerCell *tileServerCell = nil;
    NSArray *cells = [_cellArray objectAtIndex:indexPath.section];
    
    if ([[cells objectAtIndex:indexPath.row] isKindOfClass:MCTileServerCell.class]) {
        tileServerCell = (MCTileServerCell *)[cells objectAtIndex:indexPath.row];
    } else if ([[cells objectAtIndex:indexPath.row] isKindOfClass:MCLayerCell.class]) {
        layerCell = (MCLayerCell *)[cells objectAtIndex:indexPath.row];
    }
    
    UISwipeActionsConfiguration *emptyConfiguration = [UISwipeActionsConfiguration configurationWithActions:@[]];
    if (layerCell != nil) {
        return emptyConfiguration;
    } else if (tileServerCell != nil && [tileServerCell.tileServer.serverName isEqualToString:@"GEOINT Services OSM"]) {
        return emptyConfiguration;
    }
    
    UIContextualAction *editAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Edit" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        MCLayerCell *cell = [cells objectAtIndex:indexPath.row];
        [self.settingsDelegate editTileServer:cell.layerNameLabel.text];
        completionHandler(YES);
    }];
    
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        MCLayerCell *cell = [cells objectAtIndex:indexPath.row];
        [self.settingsDelegate deleteTileServer: cell.tileServer.serverName];
        completionHandler(YES);
    }];
    
    editAction.backgroundColor = [UIColor purpleColor];
    deleteAction.backgroundColor = [UIColor redColor];
    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:@[editAction, deleteAction]];
    configuration.performsFirstActionWithFullSwipe = YES;
    return configuration;
}


#pragma mark - UITextViewDelegate methods
-(BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


- (void)textFieldDidEndEditing:(UITextField *)textField {
    NSLog(@"max features: %d", [textField.text intValue]);
    
    if ([textField.text intValue] > 5000) {
        [textField setText:[NSString stringWithFormat:@"%d", 5000]];
        [self.mapSettingsDelegate setMaxFeatures:5000];
    }
    
    [textField setText:[NSString stringWithFormat:@"%d", [textField.text intValue]]];
    [self.mapSettingsDelegate setMaxFeatures:[textField.text intValue]];
}


#pragma mark - MCSegmentedControlDelegate method
- (void)selectionChanged:(NSString *)selection {
    [_mapSettingsDelegate setMapType:selection];
}


#pragma mark - MCSwitchCellDelegate
- (void) switchChanged:(id)sender {
    UISwitch *switchControl = (UISwitch*)sender;
    
    if ([sender superview] == _alertSwitchCell) {
        [self.settings setBool:[switchControl isOn] forKey:GPKGS_PROP_HIDE_MAX_FEATURES_WARNING];
    } else {
        [self.settings setBool:![switchControl isOn] forKey:GPKGS_PROP_HIDE_ZOOM_LEVEL_INDICATOR];
        [self.mapSettingsDelegate toggleZoomIndicator];
    }
    
}


#pragma mark - ButtonCell delegate
- (void)performButtonAction:(NSString *)action {
    if ([action isEqualToString:SHOW_NOTICE]) {
        [self.settingsDelegate showNoticeAndAttributeView];
    } else if ([action isEqualToString:SHOW_TILE_URL_MANAGER]) {
        [self.settingsDelegate showTileURLManager];
    }
}


@end
