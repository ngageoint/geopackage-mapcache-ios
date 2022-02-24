//
//  GPKGSTileLayerDetailsViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/9/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCTileLayerDetailsViewController.h"
#import "mapcache_ios-Swift.h"

@interface MCTileLayerDetailsViewController ()
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) MCTitleCell *titleCell;
@property (nonatomic, strong) MCButtonCell *buttonCell;
@property (nonatomic, strong) MCButtonCell *selectServerButtonCell;
@property (nonatomic, strong) MCButtonCell *helpButtonCell;
@property (nonatomic, strong) MCDescriptionCell *helpText;
@property (nonatomic, strong) MCFieldWithTitleCell *layerNameCell;
@property (nonatomic, strong) MCFieldWithTitleCell *usernameCell;
@property (nonatomic, strong) MCFieldWithTitleCell *passwordCell;
@property (nonatomic, strong) MCEmptyStateCell *spacer;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic) BOOL urlIsValid;
@property (nonatomic) BOOL haveScrolled;
@property (nonatomic) BOOL serverRequiresLogin;
@property (nonatomic) BOOL credentialsLoadedFromKeychain;
@property (nonatomic) CGFloat contentOffset;
@end

@implementation MCTileLayerDetailsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    CGRect bounds = self.view.bounds;
    CGRect insetBounds = CGRectMake(bounds.origin.x, bounds.origin.y + 32, bounds.size.width, bounds.size.height - 20);
    self.tableView = [[UITableView alloc] initWithFrame: insetBounds style:UITableViewStylePlain];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.estimatedRowHeight = 141.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.backgroundColor = [UIColor clearColor];
    
    self.layerName = nil;
    self.urlIsValid = YES;
    self.serverRequiresLogin = NO;
    self.credentialsLoadedFromKeychain = NO;
    
    MCTileServer *tileServer = [[MCTileServer alloc] initWithServerName:@"GEOINT Services OSM"];
    tileServer.url = @"https://osm.gs.mil/tiles/default/{z}/{x}/{y}.png";
    tileServer.serverType = MCTileServerTypeXyz;
    self.tileServer = tileServer;
    
    [self registerCellTypes];
    [self initCellArray];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    self.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    
    UIEdgeInsets tabBarInsets = UIEdgeInsetsMake(0, 0, self.tabBarController.tabBar.frame.size.height, 0);
    self.tableView.contentInset = tabBarInsets;
    self.tableView.scrollIndicatorInsets = tabBarInsets;
    self.contentOffset = 0;
    self.haveScrolled = NO;
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
    
    _titleCell = [self.tableView dequeueReusableCellWithIdentifier:@"title"];
    _titleCell.label.text = @"New tile layer";
    [_cellArray addObject:_titleCell];
    
    _layerNameCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    _layerNameCell.title.text = @"Layer name";
    
    if (self.layerName != nil) {
        [_layerNameCell setFieldText:self.layerName];
    } else {
        [_layerNameCell setFieldText:@""];
    }
    
    [_layerNameCell.field setReturnKeyType:UIReturnKeyDone]; // TODO look into UIReturnKeyNext
    [_layerNameCell setPlaceholder:@"Layer Name"];
    _layerNameCell.field.delegate = self;
    [_cellArray addObject:_layerNameCell];
    
    _urlCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    [_urlCell setTitleText:@"Tile server URL"];

    [_urlCell setPlaceholder:self.tileServer.url];
    [_urlCell setFieldText:self.tileServer.url];
    
    [_urlCell setTextFieldDelegate: self];
    [_urlCell useReturnKeyDone];
    [_urlCell clearButtonMode];
    [_cellArray addObject:_urlCell];
    
    self.helpText = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    self.helpText.descriptionLabel.text = @"Tip: EPSG:3857 tiles from XYZ and WMS servers are supported.";
    [_cellArray addObject:self.helpText];
    
    _selectServerButtonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [_selectServerButtonCell.button setTitle:@"Choose Tile Server" forState:UIControlStateNormal];
    _selectServerButtonCell.action = @"ShowServers";
    _selectServerButtonCell.delegate = self;
    [_selectServerButtonCell useSecondaryColors];
    [_cellArray addObject:_selectServerButtonCell];
    
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
    [_helpButtonCell useSecondaryColors];
    [_cellArray addObject:_helpButtonCell];
    
    _usernameCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    [_usernameCell setTitleText:@"Username"];
    _usernameCell.field.delegate = self;
    _passwordCell = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    [_passwordCell setTitleText:@"Password"];
    _passwordCell.field.delegate = self;
    [_passwordCell useSecureTextEntry];
    
    self.spacer = [self.tableView dequeueReusableCellWithIdentifier:@"spacer"];
    [self.spacer useAsSpacer];

}

- (void)update {
    [self initCellArray];
    [self.tableView reloadData];
    [self textFieldDidEndEditing:self.layerNameCell.field];
    [self textFieldDidEndEditing:self.urlCell.field];
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCFieldWithTitleCell" bundle:nil] forCellReuseIdentifier:@"fieldWithTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCEmptyStateCell" bundle:nil] forCellReuseIdentifier:@"spacer"];
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


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [_cellArray objectAtIndex:indexPath.row];
    
    if ([cell isKindOfClass:MCFieldWithTitleCell.class]) {
        return 105;
    } else if ([cell isKindOfClass:MCButtonCell.class]) {
        return 82;
    } else if ([cell isKindOfClass:MCTitleCell.class]) {
        return 44;
    } else if ([cell isKindOfClass:MCDescriptionCell.class]) {
        return 44;
    } else {
        return 300; // empty state cell
    }
}


#pragma mark- UITextFieldDelegate methods
- (void) textFieldDidEndEditing:(UITextField *)textField {
    [textField trimWhiteSpace];
    
    if (textField == _urlCell.field) {
        NSLog(@"URL Field ended editing");
        
        if ([textField.text isEqualToString:@""]) {
            self.urlIsValid = NO;
            [self.helpText.descriptionLabel setText:@"URL can't be blank."];
            [self.urlCell useErrorAppearance];
            [self.buttonCell disableButton];
        } else {
            [self.helpText setDescription:@"Checking URL"];
            [self.buttonCell disableButton];
            
            [[MCTileServerRepository shared] isValidServerURLWithUrlString:[self.urlCell fieldValue] completion:^(MCTileServerResult *tileServerResult) {
                if (tileServerResult == nil) {
                    NSLog(@"Bad url");
                    self.urlIsValid = NO;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.helpText.descriptionLabel setText:@"Check your URL."];
                        [self.buttonCell disableButton];
                        [self.urlCell useErrorAppearance];
                    });
                    [textField resignFirstResponder];
                    return;
                }
                
                MCServerError *error = (MCServerError *)tileServerResult.failure;
                MCTileServerType serverType = ((MCTileServer *)tileServerResult.success).serverType;
                
                if ((error == nil || error.code == MCNoError) && (serverType == MCTileServerTypeXyz || serverType == MCTileServerTypeWms)) {
                    NSLog(@"Valid URL");
                    self.tileServer = (MCTileServer *)tileServerResult.success;
                    self.urlIsValid = YES;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.urlCell useNormalAppearance];
                        BOOL isLayerNameAvailable = [self.delegate isLayerNameAvailable: self.layerName];
                        [self.helpText.descriptionLabel setText:@""];
                        if (self.layerName != nil && ![self.layerName isEqualToString:@""] && isLayerNameAvailable) {
                            [self.buttonCell enableButton];
                        }
                    });
                } else if (tileServerResult.failure != nil && error.code == MCUnauthorized) {
                    self.serverRequiresLogin = YES;
                    self.tileServer = (MCTileServer *)tileServerResult.success;
                    
                    NSMutableArray *updatedCellArray = [[NSMutableArray alloc] init];
                    [self.usernameCell useReturnKeyNext];
                    [self.passwordCell useReturnKeyDone];
                    
                    [updatedCellArray addObject:self.titleCell];
                    [updatedCellArray addObject:self.layerNameCell];
                    [updatedCellArray addObject:self.urlCell];
                    [updatedCellArray addObject:self.helpText];
                    [updatedCellArray addObject:self.selectServerButtonCell];
                    [updatedCellArray addObject:self.usernameCell];
                    [updatedCellArray addObject:self.passwordCell];
                    [updatedCellArray addObject:self.buttonCell];
                    [updatedCellArray addObject:self.spacer];
                    self.cellArray = updatedCellArray;
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.tableView reloadData];
                        [self.usernameCell.field becomeFirstResponder];
                        [self.buttonCell disableButton];
                         NSLog(@"%@", [NSString stringWithFormat:@"number of sections %ld", (long)self.tableView.numberOfSections]);
                        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(self.cellArray.count -1) inSection:0];
                        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionNone animated:YES];
                    });
                    
                    
                    MCKeychainError *keychainError = nil;
                    MCCredentials *credentials = [[MCKeychainUtil shared] readCredentialsWithServer:self.tileServer.url error: &keychainError];
                    if (keychainError) {
                        NSLog(@"Problem reading credentials from Keychain %@", [keychainError.userInfo objectForKey:@"errorCode"]);
                    } else if (credentials) {
                        [self.usernameCell setFieldText:credentials.username];
                        [self.passwordCell setFieldText:credentials.password];
                        [self.passwordCell.field becomeFirstResponder];
                        [self.passwordCell.field endEditing:YES];
                        [self.passwordCell.field resignFirstResponder];
                        self.credentialsLoadedFromKeychain = YES;
                    }
                } else if (tileServerResult.failure != nil && error.code != MCNoError) {
                    self.urlIsValid = NO;
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSDictionary *userInfo = error.userInfo;
                        [self.helpText.descriptionLabel setText:userInfo[@"message"]];
                        [self.buttonCell disableButton];
                        [self.urlCell useErrorAppearance];
                    });
                } else {
                    // TODO add TMS support
                    NSLog(@"Bad url");
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [self.buttonCell disableButton];
                        [self.urlCell useErrorAppearance];
                    });
                }
            }];
        }
    } else if (textField == _passwordCell.field) {
        [self.passwordCell.field resignFirstResponder];
        [[MCTileServerRepository shared] isValidServerURLWithUrlString:[self.urlCell fieldValue] username:[self.usernameCell fieldValue] password:[self.passwordCell fieldValue] completion:^(MCTileServerResult *tileServerResult) {
            if (tileServerResult == nil) {
                NSLog(@"Bad url");
                self.urlIsValid = NO;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.helpText.descriptionLabel setText:@"Check your URL."];
                    [self.buttonCell disableButton];
                    [self.urlCell useErrorAppearance];
                });
                
                [textField resignFirstResponder];
                return;
            }
            
            MCServerError *error = (MCServerError *)tileServerResult.failure;
            MCTileServerType serverType = ((MCTileServer *)tileServerResult.success).serverType;
            
            if (serverType == MCTileServerTypeXyz || serverType == MCTileServerTypeWms) {
                NSLog(@"Valid URL");
                self.tileServer = (MCTileServer *)tileServerResult.success;
                self.urlIsValid = YES;
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.urlCell useNormalAppearance];
                    BOOL isLayerNameAvailable = [self.delegate isLayerNameAvailable: self.layerName];
                    
                    if (self.layerName != nil && ![self.layerName isEqualToString:@""] && isLayerNameAvailable) {
                        [self.buttonCell enableButton];
                    }
                });
            } else if (tileServerResult.failure != nil && error.code == MCUnauthorized) {
                dispatch_async(dispatch_get_main_queue(), ^{;
                    [self.tableView reloadData];
                    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.cellArray.count - 1 inSection:0];
                    [self.usernameCell useErrorAppearance];
                    [self.passwordCell useErrorAppearance];
                    [self.helpText setDescription:@"Check your username and password"];
                    [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionTop animated:NO];
                    [self.usernameCell.field becomeFirstResponder];
                });
            } else if (tileServerResult.failure != nil && error.code != MCNoError) {
                self.urlIsValid = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSDictionary *userInfo = error.userInfo;
                    [self.helpText.descriptionLabel setText:userInfo[@"message"]];
                    [self.buttonCell disableButton];
                    [self.urlCell useErrorAppearance];
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
        
        if ([_layerNameCell.field.text isEqualToString:@""]) {
            [self.layerNameCell useErrorAppearance];
            [_buttonCell disableButton];
            [_layerNameCell setPlaceholder:@"Please name your layer"];
        } else if (!isLayerNameAvailable) {
            [self.layerNameCell useErrorAppearance];
            [_buttonCell disableButton];
            [self.helpText.descriptionLabel setText:@"There is already a layer with that name."];
        } else {
            [self.layerNameCell useNormalAppearance];
            
            if (self.urlIsValid) {
                [_buttonCell enableButton];
            }
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
        
        if (self.serverRequiresLogin && !self.credentialsLoadedFromKeychain) {
            UIAlertController *saveCredentialsAlert = [UIAlertController alertControllerWithTitle:@"Add to Keychain" message:@"Would you like to save your username and password so you can login with FaceID?" preferredStyle:UIAlertControllerStyleActionSheet];
            UIAlertAction *yesAction = [UIAlertAction actionWithTitle:@"Yes" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self continueToBoundingBox:YES];
            }];
            UIAlertAction *noAction = [UIAlertAction actionWithTitle:@"No" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [self continueToBoundingBox:NO];
            }];
            
            [saveCredentialsAlert addAction:yesAction];
            [saveCredentialsAlert addAction:noAction];
            [self presentViewController:saveCredentialsAlert animated:YES completion:nil];
        } else {
            [self continueToBoundingBox:NO];
        }
    } else if ([action isEqualToString:@"ShowServers"]) {
        [self.delegate showTileServerList];
    } else {
        [_delegate showURLHelp];
    }
}


- (void) continueToBoundingBox:(BOOL)saveCredentials {
    [_delegate tileLayerDetailsCompletionHandlerWithName:_layerNameCell.field.text tileServer: self.tileServer username:self.usernameCell.field.text password:self.passwordCell.field.text saveCredentials:saveCredentials andReferenceSystemCode:PROJ_EPSG_WEB_MERCATOR];
}


#pragma mark - NGADrawerView methods
- (void) closeDrawer {
    [self.drawerViewDelegate popDrawer];
}

- (void) drawerWasCollapsed {
    [super drawerWasCollapsed];
    [self.tableView setScrollEnabled:NO];
}


- (void) drawerWasMadeFull {
    [super drawerWasMadeFull];
    [self.tableView setScrollEnabled:YES];
}

- (BOOL)gestureIsInConflict:(UIPanGestureRecognizer *) recognizer {
    CGPoint point = [recognizer locationInView:self.view];
    
    if (CGRectContainsPoint(_layerNameCell.frame, point) || CGRectContainsPoint(_urlCell.frame, point)) {
        return true;
    }
    
    return false;
}

// Override this method to make the drawer and the scrollview play nice
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.haveScrolled) {
        [self rollUpPanGesture:scrollView.panGestureRecognizer withScrollView:scrollView];
    }
}

// If the table view is scrolling rollup the gesture to the drawer and handle accordingly.
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.haveScrolled = YES;
    
    if (!self.isFullView) {
        scrollView.scrollEnabled = NO;
        scrollView.scrollEnabled = YES;
    } else {
        scrollView.scrollEnabled = YES;
    }
}

@end
