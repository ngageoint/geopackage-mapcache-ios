//
//  MCNewTileServerViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/23/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "MCNewTileServerViewController.h"

@interface MCNewTileServerViewController ()
@property (nonatomic, strong) NSMutableArray *cellArray;
@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) MCFieldWithTitleCell *nameField;
@property (nonatomic, strong) MCTextViewCell *urlField;
@property (nonatomic, strong) MCButtonCell *buttonCell;
@property (nonatomic) BOOL nameIsValid;
@property (nonatomic) BOOL urlIsValid;
@end

@implementation MCNewTileServerViewController

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
    [self.urlField setPlaceholderText:@"XYZ and WMS are supported. Make sure you enter the URL template."];
    self.urlField.textViewCellDelegate = self;
    [self.cellArray addObject:self.urlField];
    
    self.buttonCell = [self.tableView dequeueReusableCellWithIdentifier:@"button"];
    [self.buttonCell setButtonLabel:@"Save Tile Server"];
    [self.buttonCell setAction:@"SAVE"];
    [self.buttonCell setDelegate:self];
    [self.buttonCell disableButton];
    [self.cellArray addObject:self.buttonCell];
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


#pragma mark - UITextFieldDelegate
- (void) textFieldDidEndEditing:(UITextField *)textField {
    [textField trimWhiteSpace:textField];
    if (textField.text && ![textField.text isEqualToString:@""]) {
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
    [textView trimWhiteSpace:textView];
    
    [textView isValidTileServerURL:textView withResult:^(BOOL isValid) {
        if (isValid) {
            NSLog(@"Valid URL");
            self.urlIsValid = YES;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.urlField useNormalAppearance];
            });
        } else {
            NSLog(@"Bad URL");
            self.urlIsValid = NO;
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.urlField useErrorAppearance];
            });
        }
    }];
    
    if (self.nameIsValid && self.urlIsValid) {
        [self.buttonCell enableButton];
    } else {
        [self.buttonCell disableButton];
    }
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
    BOOL didSave = [self.saveTileServerDelegate saveURL:[self.urlField getText] forServerNamed:[self.nameField fieldValue]];
    
    if (didSave) {
        [self.drawerViewDelegate popDrawer];
    }
}

@end
