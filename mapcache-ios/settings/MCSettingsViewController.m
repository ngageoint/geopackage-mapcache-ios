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
@end

@implementation MCSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.haveScrolled = NO;
    self.tableView = [[UITableView alloc] init];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 390.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
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
    [_cellArray addObject:titleCell];
    
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
    
    [_cellArray addObject:_baseMapSelector];
    
    MCLayerCell *ngaOSMURL = [self.tableView dequeueReusableCellWithIdentifier:@"layerCell"];
    [ngaOSMURL setName:@"GEOINT Services OSM"];
    [ngaOSMURL setDetails:@"https://osm.gs.mil/tiles/default/{z}/{x}/{y}.png"];
    [ngaOSMURL activeIndicatorOff];
    [ngaOSMURL.layerTypeImage setImage:[UIImage imageNamed:[MCProperties getValueOfProperty:GPKGS_PROP_ICON_TILE_SERVER]]];
    [self.cellArray addObject:ngaOSMURL];
    
    
    
    if (self.savedTileServers) {
        NSArray *serverURLs = [self.savedTileServers allKeys];
        for (NSString *serverURL in serverURLs) {
            MCLayerCell *tileServerCell = [self.tableView dequeueReusableCellWithIdentifier:@"layerCell"];
            MCTileServer *tileServer = [self.savedTileServers objectForKey:serverURL];
            
            [tileServerCell setName: tileServer.serverName];            
            NSMutableArray *wmsLayers = [[NSMutableArray alloc] init];
            
            if (tileServer.serverType == MCTileServerTypeWms) {
                NSString *layerLabel = tileServer.layers.count == 1? @"layer" : @"layers";
                NSString *details = [NSString stringWithFormat:@"%lu %@", (unsigned long)tileServer.layers.count, layerLabel];
                [tileServerCell setDetails: details];
                
                for (MCLayer *layer in tileServer.layers) {
                    MCLayerCell *layerCell = [self.tableView dequeueReusableCellWithIdentifier:@"layerCell"];
                    [layerCell.layerTypeImage setImage:[UIImage imageNamed:@"Layer"]];
                    [layerCell setName:layer.title];
                    [layerCell activeIndicatorOff];
                    [wmsLayers addObject:layerCell];
                }
            } else {
                [tileServerCell setDetails: tileServer.serverName];
            }
            
            [tileServerCell.layerTypeImage setImage:[UIImage imageNamed:[MCProperties getValueOfProperty:GPKGS_PROP_ICON_TILE_SERVER]]];
            [tileServerCell activeIndicatorOff];
            [self.cellArray addObject:tileServerCell];
            [self.cellArray addObjectsFromArray:wmsLayers];
        }
    }
    
    MCButtonCell *tileURLServerManagerButtonCell = [self.tableView dequeueReusableCellWithIdentifier:@"buttonCell"];
    [tileURLServerManagerButtonCell setButtonLabel:@"New Tile Server"];
    tileURLServerManagerButtonCell.action = SHOW_TILE_URL_MANAGER;
    tileURLServerManagerButtonCell.delegate = self;
    [_cellArray addObject:tileURLServerManagerButtonCell];
    
    _maxFeaturesCell = [_tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _maxFeaturesCell.title.text = @"Maximum number of features";
    int maxFeatures = (int)[self.settings integerForKey:GPKGS_PROP_MAP_MAX_FEATURES];
    if(maxFeatures == 0){
        maxFeatures = [[MCProperties getNumberValueOfProperty:GPKGS_PROP_MAP_MAX_FEATURES_DEFAULT] intValue];
    }
    _maxFeaturesCell.field.text = [NSString stringWithFormat:@"%d", maxFeatures];
    [_maxFeaturesCell setTextFielDelegate:self];
    [_maxFeaturesCell setupNumericalKeyboard];
    [_cellArray addObject:_maxFeaturesCell];
    
    _alertSwitchCell = [_tableView dequeueReusableCellWithIdentifier:@"switchCell"];
    _alertSwitchCell.label.text = @"Max feature warning";
    _alertSwitchCell.switchDelegate = self;
    BOOL hideWarning = [self.settings boolForKey:GPKGS_PROP_HIDE_MAX_FEATURES_WARNING];
    if (hideWarning) {
        [_alertSwitchCell switchOn];
    } else {
        [_alertSwitchCell switchOff];
    }
    [_cellArray addObject:_alertSwitchCell];
    
    _zoomSwitchCell = [_tableView dequeueReusableCellWithIdentifier:@"switchCell"];
    _zoomSwitchCell.label.text = @"Zoom level indicator";
    _zoomSwitchCell.switchDelegate = self;
    BOOL hideZoomIndicator = [self.settings boolForKey:GPKGS_PROP_HIDE_ZOOM_LEVEL_INDICATOR];
    if (hideZoomIndicator) {
        [_zoomSwitchCell switchOff];
    } else {
        [_zoomSwitchCell switchOn];
    }
    [_cellArray addObject:_zoomSwitchCell];
    
    MCButtonCell *showNoticesButtonCell = [self.tableView dequeueReusableCellWithIdentifier:@"buttonCell"];
    [showNoticesButtonCell setButtonLabel:@"About MapCache"];
    showNoticesButtonCell.action = SHOW_NOTICE;
    showNoticesButtonCell.delegate = self;
    [showNoticesButtonCell useSecondaryColors];
    [_cellArray addObject:showNoticesButtonCell];

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
}


#pragma mark - TableView delegate methods
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [_cellArray objectAtIndex:indexPath.row];
}
    

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cellArray count];
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
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


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[_cellArray objectAtIndex:indexPath.row] isKindOfClass:[MCLayerCell class]]) {
        return YES;
    }
      
    return NO;
}


- (UISwipeActionsConfiguration *) tableView:(UITableView *)tableView leadingSwipeActionsConfigurationForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    MCLayerCell *cell = (MCLayerCell *)[_cellArray objectAtIndex:indexPath.row];
    
    UIContextualAction *toggleAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleNormal title:@"Add to map" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        //[self.delegate toggleLayer: cell.table];
        // TODO wire this up
        [self.mapSettingsDelegate updateBasemaps];
        [cell toggleActiveIndicator];
        completionHandler(YES);
    }];
    
    if ([cell.activeIndicator isHidden]) {
        toggleAction.backgroundColor = [UIColor colorWithRed:0.13 green:0.31 blue:0.48 alpha:1.0];
        toggleAction.title = @"Show on map";
    } else {
        toggleAction.backgroundColor = [UIColor grayColor];
        toggleAction.title = @"Hide from map";
    }
    
    UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:@[toggleAction]];
    configuration.performsFirstActionWithFullSwipe = YES;
    return configuration;
}


- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    // if the server is the default NGA OSM server, dont let them edit or delete it
    if ([[_cellArray objectAtIndex:indexPath.row] isKindOfClass:[MCLayerCell class]]) {
        MCLayerCell *cell = [_cellArray objectAtIndex:indexPath.row];
        if ([cell.layerNameLabel.text isEqualToString:@"GEOINT Services OSM"]) {
            UISwipeActionsConfiguration *configuration = [UISwipeActionsConfiguration configurationWithActions:@[]];
            return configuration;
        }
    }
    
    UIContextualAction *editAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Edit" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        MCLayerCell *cell = [self.cellArray objectAtIndex:indexPath.row];
        [self.settingsDelegate editTileServer:cell.layerNameLabel.text];
        completionHandler(YES);
    }];
    
    UIContextualAction *deleteAction = [UIContextualAction contextualActionWithStyle:UIContextualActionStyleDestructive title:@"Delete" handler:^(UIContextualAction * _Nonnull action, __kindof UIView * _Nonnull sourceView, void (^ _Nonnull completionHandler)(BOOL)) {
        MCLayerCell *cell = [self.cellArray objectAtIndex:indexPath.row];
        [self.settingsDelegate deleteTileServer: cell.layerNameLabel.text];
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
