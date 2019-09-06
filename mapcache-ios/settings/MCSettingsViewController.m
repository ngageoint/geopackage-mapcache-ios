//
//  MCSettingsViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/5/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCSettingsViewController.h"

NSString * const SHOW_NOTICE = @"showNotice";

@interface MCSettingsViewController ()
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) MCSegmentedControlCell *baseMapSelector;
@property (nonatomic, strong) MCFieldWithTitleCell *maxFeaturesCell;
@property (nonatomic, strong) MCSwitchCell *alertSwitchCell;
@property (nonatomic, strong) MCSwitchCell *zoomSwitchCell;
@property (nonatomic, strong) NSUserDefaults *settings;
@end

@implementation MCSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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


- (void) closeDrawer {
    [super closeDrawer];
    [_settingsDelegate settingsCompletionHandler];
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
    NSArray *maps = [[NSArray alloc] initWithObjects: [GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_STANDARD],
                     [GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_SATELLITE],
                     [GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_HYBRID], nil];
    
    [_baseMapSelector setItems:maps];
    
    NSString *mapType = [self.settings stringForKey:GPKGS_PROP_MAP_TYPE];
    if (mapType == nil || [mapType isEqualToString:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_STANDARD]]) {
        [_baseMapSelector.segmentedControl setSelectedSegmentIndex:0];
    } else if ([mapType isEqualToString:[GPKGSProperties getValueOfProperty:GPKGS_PROP_MAP_TYPE_SATELLITE]]) {
        [_baseMapSelector.segmentedControl setSelectedSegmentIndex:1];
    } else {
        [_baseMapSelector.segmentedControl setSelectedSegmentIndex:2];
    }
    
    [_cellArray addObject:_baseMapSelector];
    
    _maxFeaturesCell = [_tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _maxFeaturesCell.title.text = @"Maximum number of features";
    int maxFeatures = (int)[self.settings integerForKey:GPKGS_PROP_MAP_MAX_FEATURES];
    if(maxFeatures == 0){
        maxFeatures = [[GPKGSProperties getNumberValueOfProperty:GPKGS_PROP_MAP_MAX_FEATURES_DEFAULT] intValue];
    }
    _maxFeaturesCell.field.text = [NSString stringWithFormat:@"%d", maxFeatures];
    [_maxFeaturesCell setTextFielDelegate:self];
    [_maxFeaturesCell setupNumericalKeyboard];
    [_cellArray addObject:_maxFeaturesCell];
    
    _alertSwitchCell = [_tableView dequeueReusableCellWithIdentifier:@"switchCell"];
    _alertSwitchCell.label.text = @"Show max feature warning";
    _alertSwitchCell.switchDelegate = self;
    BOOL hideWarning = [self.settings boolForKey:GPKGS_PROP_HIDE_MAX_FEATURES_WARNING];
    if (hideWarning) {
        [_alertSwitchCell switchOn];
    } else {
        [_alertSwitchCell switchOff];
    }
    [_cellArray addObject:_alertSwitchCell];
    
    _zoomSwitchCell = [_tableView dequeueReusableCellWithIdentifier:@"switchCell"];
    _zoomSwitchCell.label.text = @"Show zoom level indicator";
    _zoomSwitchCell.switchDelegate = self;
    BOOL hideZoomIndicator = [self.settings boolForKey:GPKGS_PROP_HIDE_ZOOM_LEVEL_INDICATOR];
    if (hideZoomIndicator) {
        [_zoomSwitchCell switchOff];
    } else {
        [_zoomSwitchCell switchOn];
    }
    [_cellArray addObject:_zoomSwitchCell];
    
    
    MCButtonCell *showNoticesButtonCell = [self.tableView dequeueReusableCellWithIdentifier:@"buttonCell"];
    [showNoticesButtonCell.button setTitle:@"About MapCache" forState:UIControlStateNormal];
    showNoticesButtonCell.action = SHOW_NOTICE;
    showNoticesButtonCell.delegate = self;
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
}


#pragma mark - TableView delegate methods
- (nonnull UITableViewCell *)tableView:(nonnull UITableView *)tableView cellForRowAtIndexPath:(nonnull NSIndexPath *)indexPath {
    return [_cellArray objectAtIndex:indexPath.row];
}
    

- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_cellArray count];
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
        [self.settingsDelegate setMaxFeatures:5000];
    }
    
    [textField setText:[NSString stringWithFormat:@"%d", [textField.text intValue]]];
    [self.settingsDelegate setMaxFeatures:[textField.text intValue]];
}


#pragma mark - MCSegmentedControlDelegate method
- (void)selectionChanged:(NSString *)selection {
    [_settingsDelegate setMapType:selection];
}


#pragma mark - MCSwitchCellDelegate
- (void) switchChanged:(id)sender {
    UISwitch *switchControl = (UISwitch*)sender;
    
    if ([sender superview] == _alertSwitchCell) {
        [self.settings setBool:[switchControl isOn] forKey:GPKGS_PROP_HIDE_MAX_FEATURES_WARNING];
    } else {
        [self.settings setBool:![switchControl isOn] forKey:GPKGS_PROP_HIDE_ZOOM_LEVEL_INDICATOR];
        [self.settingsDelegate toggleZoomIndicator];
    }
    
}


#pragma mark - ButtonCell delegate
- (void)performButtonAction:(NSString *)action {
    if ([action isEqualToString:SHOW_NOTICE]) {
        [self.noticeAndAttributeDelegate showNoticeAndAttributeView];
    }
}


@end
