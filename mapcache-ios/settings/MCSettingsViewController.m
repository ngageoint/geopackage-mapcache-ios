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
@property (nonatomic, strong) MCSegmentedControlCell *gridOverlaySelector;
@property (nonatomic, strong) MCFieldWithTitleCell *maxFeaturesCell;
@property (nonatomic, strong) MCSwitchCell *alertSwitchCell;
@property (nonatomic, strong) MCSwitchCell *zoomSwitchCell;
@property (nonatomic, strong) NSUserDefaults *settings;
@property (nonatomic) BOOL haveScrolled;
@property (nonatomic, strong) NSMutableDictionary *savedTileServers;
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
    self.tableView.backgroundColor = [UIColor colorNamed:@"ngaBackgroundColor"];
    self.savedTileServers = [[NSMutableDictionary alloc] initWithDictionary: [[MCTileServerRepository shared] getTileServers]];
    [self registerCellTypes];
    [self initCellArray];
    [self addAndConstrainSubview:self.tableView];
}


- (void)viewWillDisappear:(BOOL)animated {
    [_mapSettingsDelegate settingsCompletionHandler];
}


- (void) update {
    self.savedTileServers = [[MCTileServerRepository shared] getTileServers];
    [self initCellArray];
    [self.tableView reloadData];
}


- (void) closeDrawer {
    [_mapSettingsDelegate settingsCompletionHandler];
}


- (void)initCellArray {
    _cellArray = [[NSMutableArray alloc] init];
    
    MCTitleCell *titleCell = [_tableView dequeueReusableCellWithIdentifier:@"title"];
    titleCell.label.text = @"Settings";
    
    
    self.settings = [NSUserDefaults standardUserDefaults];
    _baseMapSelector = [_tableView dequeueReusableCellWithIdentifier:@"segmentedControl"];
    _baseMapSelector.label.text = [MCProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE];
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
    
    _gridOverlaySelector = [_tableView dequeueReusableCellWithIdentifier:@"segmentedControl"];
    _gridOverlaySelector.label.text = [MCProperties getValueOfProperty:GPKGS_PROP_GRID_TYPE];
    _gridOverlaySelector.delegate = self;
    NSArray *grids = [[NSArray alloc] initWithObjects: [MCProperties getValueOfProperty:GPKGS_PROP_GRID_TYPE_NONE],
                     [MCProperties getValueOfProperty:GPKGS_PROP_GRID_TYPE_GARS],
                     [MCProperties getValueOfProperty:GPKGS_PROP_GRID_TYPE_MGRS], nil];
    [_gridOverlaySelector updateItems:grids];
    
    NSString *gridType = [self.settings stringForKey:GPKGS_PROP_GRID_TYPE];
    if (gridType == nil || [gridType isEqualToString:[MCProperties getValueOfProperty:GPKGS_PROP_GRID_TYPE_NONE]]) {
        [_gridOverlaySelector.segmentedControl setSelectedSegmentIndex:0];
    } else if ([gridType isEqualToString:[MCProperties getValueOfProperty:GPKGS_PROP_GRID_TYPE_GARS]]) {
        [_gridOverlaySelector.segmentedControl setSelectedSegmentIndex:1];
    } else {
        [_gridOverlaySelector.segmentedControl setSelectedSegmentIndex:2];
    }
    
    NSArray *topCells = @[titleCell, _baseMapSelector, _gridOverlaySelector];
    [_cellArray addObject:topCells];
    
    MCTileServer *defaultServer = [[MCTileServer alloc] initWithServerName:@"GEOINT Services OSM"];
    defaultServer.url = @"https://osm.gs.mil/tiles/default/{z}/{x}/{y}.png";
    defaultServer.serverType = MCTileServerTypeXyz;
    MCTileServerCell *defaultServerCell = [self.tableView dequeueReusableCellWithIdentifier:@"tileServerCell"];
    [defaultServerCell setContentWithTileServer:defaultServer];
    
    if ([self.basemapTileServer.serverName isEqualToString:defaultServer.serverName]) {
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
            
            if ([self.basemapTileServer.serverName isEqualToString:tileServer.serverName]) {
                [tileServerCell activeIndicatorOn];
            } else {
                [tileServerCell activeIndicatorOff];
            }
            
            NSMutableArray *wmsLayers = [[NSMutableArray alloc] init];
            
            if (tileServer.serverType == MCTileServerTypeWms) {
                NSString *layerLabel = tileServer.layers.count == 1? @"layer" : @"layers";
                NSString *details = [NSString stringWithFormat:@"%lu %@", (unsigned long)tileServer.layers.count, layerLabel];
                [tileServerCell setLayersLabelText:details];
                
                if ([self.expandedServer.serverName isEqualToString:tileServer.serverName]) {
                    for (MCLayer *layer in tileServer.layers) {
                        if (![layer.name isEqualToString:@""]) {
                            MCLayerCell *layerCell = [self.tableView dequeueReusableCellWithIdentifier:@"layerCell"];
                            [layerCell setContentsWithLayer:layer tileServer:tileServer];
                            
                            if ([self.basemapTileServer.serverName isEqualToString: tileServer.serverName] && [self.basemapLayer.name isEqualToString: layer.name]) {
                                [layerCell activeIndicatorOn];
                            }
                            
                            [wmsLayers addObject:layerCell];
                        }
                    }
                }
            } else if (tileServer.serverType == MCTileServerTypeAuthRequired) {
                [tileServerCell.icon setImage:[UIImage imageNamed:[MCProperties getValueOfProperty:MC_PROP_ICON_TILE_SERVER_LOGIN]]];
                [tileServerCell setLayersLabelText:@"Tap to login"];
                [tileServerCell activeIndicatorOff];
            } else if (tileServer.serverType == MCTileServerTypeError) {
                [tileServerCell.icon setImage:[UIImage imageNamed:[MCProperties getValueOfProperty:MC_PROP_ICON_TILE_SERVER_ERROR]]];
                [tileServerCell setLayersLabelText:@"Unable to reach server"];
                [tileServerCell activeIndicatorOff];
            } else {
                [tileServerCell.icon setImage:[UIImage imageNamed:[MCProperties getValueOfProperty:GPKGS_PROP_ICON_TILE_SERVER]]];
            }
            
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
    [_maxFeaturesCell setTextFieldDelegate:self];
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
        } else if (tappedServer.serverType == MCTileServerTypeAuthRequired) {
            NSError *keychainError = nil;
            MCCredentials *credentials = [[MCKeychainUtil shared] readCredentialsWithServer:tappedServer.url error:&keychainError];
            
            if (keychainError) {
                NSLog(@"Problem reading credentials from Keychain %@", [keychainError.userInfo objectForKey:@"errorCode"]);
                NSNumber *errorCode = [keychainError.userInfo objectForKey:@"errorCode"];
                if (errorCode == [NSNumber numberWithInt:-25300]) {
                    NSLog(@"Item not found error");
                    
                    UIAlertController *loginAlert = [UIAlertController alertControllerWithTitle:@"Sign in to continue" message:@"" preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *signInAction = [UIAlertAction actionWithTitle:@"Sign In" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        NSLog(@"Alert closed");
                        // TODO: grab credentials and do some things
                    }];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {}];
                    [loginAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                                            textField.placeholder = @"Username";
                    }];
                    [loginAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                                            textField.placeholder = @"Password";
                                            textField.secureTextEntry = YES;
                    }];
                    [loginAlert addAction:signInAction];
                    [loginAlert addAction:cancelAction];
                    [self presentViewController:loginAlert animated:YES completion:nil];
                }
                
            } else {
                [[MCTileServerRepository shared] isValidServerURLWithUrlString:tappedServer.url username:credentials.username password:credentials.password completion:^(MCTileServerResult *tileServerResult) {
                    if (tileServerResult == nil) {
                        NSLog(@"Problem with URL");
                    }
                    
                    MCServerError *error = (MCServerError *)tileServerResult.failure;
                    MCTileServer *tileServer = tileServerResult.success;
                    MCTileServerType serverType = tileServer.serverType;
                    tileServer.serverName = tappedServer.serverName;
                    
                    if (serverType == MCTileServerTypeXyz || serverType == MCTileServerTypeWms) {
                        [self.savedTileServers setValue:tileServer forKey:tileServer.url];
                    }
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self initCellArray];
                        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:1] withRowAnimation:UITableViewRowAnimationFade];
                    });
                }];
            }
        }
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
                    self.basemapTileServer = tileServerCell.tileServer;
                    self.basemapLayer = [[MCLayer alloc] init];
                    [self.settingsDelegate setUserBasemap:tileServerCell.tileServer layer:[[MCLayer alloc] init]];
                } else {
                    [self.settingsDelegate setUserBasemap:nil layer:nil];
                    self.basemapTileServer = [[MCTileServer alloc] init];
                    self.basemapLayer = [[MCLayer alloc] init];
                }
            }
            
            [self updateActiveIndicators];
        } else if (layerCell != nil) {
            if ([layerCell.activeIndicator isHidden]) {
                self.basemapTileServer = layerCell.tileServer;
                self.basemapLayer = layerCell.mapLayer;
                [self->_settingsDelegate setUserBasemap:layerCell.tileServer layer:layerCell.mapLayer];
            } else {
                [self.settingsDelegate setUserBasemap:nil layer:nil];
                self.basemapTileServer = [[MCTileServer alloc] init];
                self.basemapLayer = [[MCLayer alloc] init];
                [layerCell activeIndicatorOff];
            }
            
            [layerCell toggleActiveIndicator];
            [self updateActiveIndicators];
        }
        
        completionHandler(YES);
    }];
    
    if (tileServerCell != nil) {
        if (tileServerCell.tileServer.serverType == MCTileServerTypeXyz) {
            if ([tileServerCell.visibilityStatusIndicator isHidden]) {
                [toggleAction setBackgroundColor: [UIColor colorWithRed:0.13 green:0.31 blue:0.48 alpha:1.0]];
                [toggleAction setTitle:@"Use as basemap"];
            } else {
                [toggleAction setBackgroundColor: [UIColor grayColor]];
                [toggleAction setTitle:@"Remove basemap"];
            }
        }
    } else if (layerCell != nil) {
        if ([layerCell.activeIndicator isHidden]) {
            [toggleAction setBackgroundColor: [UIColor colorWithRed:0.13 green:0.31 blue:0.48 alpha:1.0]];
            [toggleAction setTitle:@"Use layer as basemap"];
        } else {
            [toggleAction setBackgroundColor: [UIColor grayColor]];
            [toggleAction setTitle: @"Remove basemap"];
        }
    }
    
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
        MCTileServerCell *cell = [cells objectAtIndex:indexPath.row];
        [self.settingsDelegate editTileServer:cell.tileServer.serverName];
        completionHandler(YES);
    }];
    
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        MCTileServerCell *cell = [cells objectAtIndex:indexPath.row];
        [self.settingsDelegate deleteTileServer: cell.tileServer];
        completionHandler(YES);
    }];
    
    editAction.backgroundColor = [UIColor purpleColor];
    deleteAction.backgroundColor = [UIColor redColor];
    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:@[editAction, deleteAction]];
    configuration.performsFirstActionWithFullSwipe = YES;
    return configuration;
}


- (void) updateActiveIndicators {
    for (UITableViewCell *cell in self.cellArray[1]) {
        if ([cell isKindOfClass:MCTileServerCell.class]) {
            MCTileServerCell *serverCell = (MCTileServerCell*)cell;
            
            if ([serverCell.tileServer.serverName isEqualToString:self.basemapTileServer.serverName]) {
                [serverCell toggleActiveIndicator];
            } else {
                [serverCell activeIndicatorOff];
            }
        } else if ([cell isKindOfClass:MCLayerCell.class]) {
            MCLayerCell *layerCell = (MCLayerCell *)cell;
            
            if (![layerCell.mapLayer.name isEqualToString:self.basemapLayer.name]) {
                [layerCell activeIndicatorOff];
            }
        }
    }
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
