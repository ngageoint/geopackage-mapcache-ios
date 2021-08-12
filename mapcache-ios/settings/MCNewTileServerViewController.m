//
//  MCNewTileServerViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/23/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "MCNewTileServerViewController.h"
#import "mapcache_ios-Swift.h"

@interface MCNewTileServerViewController ()
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) MCFieldWithTitleCell *nameField;
@property (nonatomic, strong) MCTextViewCell *urlField;
@property (nonatomic, strong) MCButtonCell *buttonCell;
@property (nonatomic, strong) MCTileServer *tileServer;
@property (nonatomic, strong) MCDescriptionCell *statusCell;
@property (nonatomic, strong) NSString *serverName;
@property (nonatomic, strong) NSString *serverURL;
@property (nonatomic) BOOL nameIsValid;
@property (nonatomic) BOOL urlIsValid;
@end

@implementation MCNewTileServerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] init];
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 100.0;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.allowsMultipleSelectionDuringEditing = NO;
    [self registerCellTypes];
    [self initCellArray];
    
    [self addAndConstrainSubview:self.tableView];
    [self addDragHandle];
    [self addCloseButton];
    
    self.nameIsValid = NO;
    self.urlIsValid = NO;
}


- (void) initCellArray {
    self.cellArray = [[NSMutableArray alloc] init];
    
    MCTitleCell *tileTitle = [self.tableView dequeueReusableCellWithIdentifier:@"title"];
    [tileTitle.label setText:@"New Tile Server"];
    [self.cellArray addObject:tileTitle];
    
    self.nameField = [self.tableView dequeueReusableCellWithIdentifier:@"fieldWithTitle"];
    [self.nameField setTitleText:@"Server name"];
    [self.nameField setPlaceholder:@"My map sever"];
    [self.nameField useReturnKeyDone];
    [self.nameField setTextFielDelegate:self];
    [self.cellArray addObject:self.nameField];
    
    self.urlField = [self.tableView dequeueReusableCellWithIdentifier:@"textView"];
    [self.urlField setPlaceholderText:@"yourtileserverurl.com\nXYZ and WMS tile servers are supported."];
    self.urlField.textViewCellDelegate = self;
    UIToolbar *keyboardToolbar = [MCUtils buildKeyboardDoneToolbarWithTarget:self andAction:@selector(doneButtonPressed)];
    self.urlField.textView.inputAccessoryView = keyboardToolbar;
    [self.cellArray addObject:self.urlField];
    
    self.buttonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [self.buttonCell setButtonLabel:@"Save Tile Server"];
    [self.buttonCell setAction:@"SAVE"];
    self.buttonCell.delegate = self;
    [self.buttonCell disableButton];
    [self.cellArray addObject:self.buttonCell];
    
    self.statusCell = [self.tableView dequeueReusableCellWithIdentifier:@"description"];
    [self.statusCell.descriptionLabel setText:@""];
    [self.cellArray addObject:self.statusCell];
}


- (void) registerCellTypes {
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTitleCell" bundle:nil] forCellReuseIdentifier:@"title"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCFieldWithTitleCell" bundle:nil] forCellReuseIdentifier:@"fieldWithTitle"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCDescriptionCell" bundle:nil] forCellReuseIdentifier:@"description"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCButtonCell" bundle:nil] forCellReuseIdentifier:@"button"];
    [self.tableView registerNib:[UINib nibWithNibName:@"MCTextViewCell" bundle:nil] forCellReuseIdentifier:@"textView"];
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


- (BOOL) textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}


- (void) doneButtonPressed {
    [self.urlField.textView replaceEncodedCharacters:self.urlField.textView];
    [self.urlField.textView resignFirstResponder];
}


#pragma mark - UITextFieldDelegate
- (void) textFieldDidEndEditing:(UITextField *)textField {
    [textField trimWhiteSpace];
    _serverName = textField.text;
    
    if (_serverName && ![_serverName isEqualToString:@""]) {
        self.nameIsValid = YES;
        [self.nameField useNormalAppearance];
    } else {
        self.nameIsValid = NO;
        [self.nameField useErrorAppearance];
    }
    
    if (self.nameIsValid && self.urlIsValid) {
        [self.buttonCell enableButton];
    } else {
        [self.buttonCell disableButton];
    }
}


#pragma mark - MCTextViewCellDelegate
- (void)textViewCellDidEndEditing:(UITextView *)textView {
    [self.statusCell.descriptionLabel setText:@"Processing layers from server, this may take a moment."];
    NSIndexPath *cellPath = [self.tableView indexPathForCell:self.statusCell];
    [self.tableView reloadRowsAtIndexPaths:@[cellPath
    ] withRowAnimation:UITableViewRowAnimationNone];
    
    _serverURL = textView.text;
    
    [textView trimWhiteSpace:textView];
    [textView isValidTileServerURL:textView withResult:^(MCTileServerResult * _Nonnull tileServerResult) {
        MCServerError *error = (MCServerError *)tileServerResult.failure;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.statusCell.descriptionLabel setText:@""];
        });
        
        if (tileServerResult.failure != nil && error.code != MCNoError) {
            NSLog(@"Bad URL");
            self.urlIsValid = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.urlField useErrorAppearance];
                [self.buttonCell disableButton];
                NSDictionary *userInfo = error.userInfo;
                
                [self.statusCell.descriptionLabel setText:userInfo[@"message"]];
                
                NSIndexPath *cellPath = [self.tableView indexPathForCell:self.statusCell];
                [self.tableView reloadRowsAtIndexPaths:@[cellPath
                ] withRowAnimation:UITableViewRowAnimationNone];
            });
        } else {
            NSLog(@"Valid URL");
            self.urlIsValid = YES;
            self.tileServer = (MCTileServer *)tileServerResult.success;
            
            if (self.tileServer.serverType == MCTileServerTypeWms && [self.serverName  isEqualToString: @""]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.nameField setFieldText:self.tileServer.serverName];
                });
            }
            
            if (self.nameIsValid) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self.urlField useNormalAppearance];
                    [self.buttonCell enableButton];
                });
            }
        }
    }];
}



- (void) setServerName:(NSString *) serverName {
    [self.nameField setFieldText:serverName];
}


- (void) setServerURL:(NSString *) serverURL {
    [self.urlField setTextViewContent:serverURL];
}


#pragma mark - NGADrawerView methods
- (void) closeDrawer {
    [self.drawerViewDelegate popDrawer];
}


#pragma mark - GPKGSButtonCellDelegate methods
- (void) performButtonAction:(NSString *)action {
    BOOL didSave = [self.saveTileServerDelegate saveURL:self.serverURL forServerNamed:self.serverName tileServer:self.tileServer];
    
    if (didSave) {
        [self.drawerViewDelegate popDrawer];
    } else {
        NSLog(@"Problem saving tile server");
        // TODO: let the user know
    }
}

@end
