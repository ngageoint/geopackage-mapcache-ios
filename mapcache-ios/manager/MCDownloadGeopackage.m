//
//  GPKGSDownloadFileViewController.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/9/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "MCDownloadGeopackage.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGIOUtils.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "GPKGSUtils.h"

@interface MCDownloadGeopackage ()

@property (nonatomic) BOOL active;
@property (nonatomic) BOOL prefillExample;
@property (nonatomic, strong) NSNumber * progress;
@property (nonatomic, strong) NSNumber * maxProgress;
@property (nonatomic) BOOL haveScrolled;
@end

@implementation MCDownloadGeopackage

#define TAG_PRELOADED 1

- (instancetype) initAsFullView:(BOOL) isFullView withExample:(BOOL) prefillExample {
    self = [super initAsFullView:isFullView];
    self.prefillExample = prefillExample;
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [GPKGSUtils disableButton:self.importButton];
    UIToolbar *keyboardToolbar = [GPKGSUtils buildKeyboardDoneToolbarWithTarget:self andAction:@selector(doneButtonPressed)];
    
    self.nameTextField.inputAccessoryView = keyboardToolbar;
    self.urlTextField.inputAccessoryView = keyboardToolbar;
    self.nameTextField.delegate = self;
    self.urlTextField.delegate = self;
    
    [self.cancelButton setHidden:YES];
    [self.downloadedLabel setHidden:YES];
    [self.progressView setHidden:YES];
    [self.importButton setTitle:@"Download" forState:UIControlStateNormal];
    self.haveScrolled = NO;
    
    if (_prefillExample) {
        NSArray * urls = [GPKGSProperties getArrayOfProperty:GPKGS_PROP_PRELOADED_GEOPACKAGE_URLS];
        NSDictionary * url = (NSDictionary *)[urls objectAtIndex:0];
        [self.nameTextField setText:[url objectForKey:GPKGS_PROP_PRELOADED_GEOPACKAGE_URLS_NAME]];
        [self.urlTextField setText:[url objectForKey:GPKGS_PROP_PRELOADED_GEOPACKAGE_URLS_URL]];
        [self validateURLField];
    }
}


- (BOOL)gestureIsInConflict:(UIPanGestureRecognizer *) recognizer {
    CGPoint point = [recognizer locationInView:self.view];
    
    if (CGRectContainsPoint(self.nameTextField.frame, point) || CGRectContainsPoint(self.urlTextField.frame, point)
        || CGRectContainsPoint(self.scrollView.frame, point)) {
        return true;
    }
    
    return false;
}


- (void) doneButtonPressed {
    [self.nameTextField resignFirstResponder];
    [self.urlTextField resignFirstResponder];
}


- (IBAction)closeDownload:(id)sender {
    [self.drawerViewDelegate popDrawer];
}


- (IBAction)cancel:(id)sender {
    if(self.active){
        self.active = false;
        [self.importButton setTitle:@"Import" forState:UIControlStateNormal];
        [GPKGSUtils enableButton:self.preloadedButton];
        [GPKGSUtils enableButton:self.importButton];
        [GPKGSUtils enableTextField:self.urlTextField];
        [GPKGSUtils enableTextField:self.nameTextField];
        [self.cancelButton setHidden:YES];
        [self.downloadedLabel setHidden:YES];
        [self.progressView setHidden:YES];
    }else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)preloaded:(id)sender {
    NSMutableArray * options = [[NSMutableArray alloc] init];
    NSArray * urls = [GPKGSProperties getArrayOfProperty:GPKGS_PROP_PRELOADED_GEOPACKAGE_URLS];
    for(NSDictionary * url in urls){
        [options addObject:[url objectForKey:GPKGS_PROP_PRELOADED_GEOPACKAGE_URLS_LABEL]];
    }
    
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_IMPORT_URL_PRELOADED_LABEL]
                          message:nil
                          delegate:self
                          cancelButtonTitle:nil
                          otherButtonTitles:nil];
    
    for (NSString *option in options) {
        [alert addButtonWithTitle:option];
    }
    alert.cancelButtonIndex = [alert addButtonWithTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_CANCEL_LABEL]];
    
    alert.tag = TAG_PRELOADED;
    
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    switch(alertView.tag){
            
        case TAG_PRELOADED:
            if(buttonIndex >= 0){
                NSArray * urls = [GPKGSProperties getArrayOfProperty:GPKGS_PROP_PRELOADED_GEOPACKAGE_URLS];
                if(buttonIndex < [urls count]){
                    NSDictionary * url = (NSDictionary *)[urls objectAtIndex:buttonIndex];
                    [self.nameTextField setText:[url objectForKey:GPKGS_PROP_PRELOADED_GEOPACKAGE_URLS_NAME]];
                    [self.urlTextField setText:[url objectForKey:GPKGS_PROP_PRELOADED_GEOPACKAGE_URLS_URL]];
                    [self validateURLField];
                }
            }
            
            break;
    }
}

- (IBAction)import:(id)sender {
    [self.importButton setTitle:@"Downloading" forState:UIControlStateNormal];
    [self.cancelButton setHidden:NO];
    [self.downloadedLabel setHidden:NO];
    [self.progressView setHidden:NO];
    
    [GPKGSUtils disableButton:self.preloadedButton];
    [GPKGSUtils disableButton:self.importButton];
    [GPKGSUtils disableTextField:self.urlTextField];
    [GPKGSUtils disableTextField:self.nameTextField];
    
    GPKGGeoPackageManager * manager = [GPKGGeoPackageFactory manager];
    
    self.active = true;
    self.progress = [NSNumber numberWithInt:0];
    self.progressView.hidden = false;
    
    @try {
        NSURL *url = [NSURL URLWithString:self.urlTextField.text];
        [manager importGeoPackageFromUrl:url withName:self.nameTextField.text andProgress:self];
    }
    @catch (NSException *e) {
        NSLog(@"Download File Error for url '%@' with error: %@", self.urlTextField.text, [e description]);
        [self failureWithError:[e description]];
    }@finally{
        [manager close];
    }

}


-(void) updateProgress{
    if(self.maxProgress != nil){
        float progress = [self.progress floatValue] / [self.maxProgress floatValue];
        
        if (progress == 1.0) {
            [self.downloadedLabel setText:@"Adding to database..."];
            [_delegate downloadFileViewController:self downloadedFile:YES withError:nil];
        } else {
            [self.downloadedLabel setText:[NSString stringWithFormat:@" %@ of %@", [GPKGIOUtils formatBytes:[self.progress intValue]], [GPKGIOUtils formatBytes:[self.maxProgress intValue]]]];
        }
        [self.progressView setProgress:progress];
    }
}

-(void) setMax: (int) max{
    self.maxProgress = [NSNumber numberWithInt:max];
    [self updateProgress];
}

-(void) addProgress: (int) progress{
    self.progress = [NSNumber numberWithInt:[self.progress intValue] + progress];
    [self updateProgress];
}

-(BOOL) isActive{
    return self.active;
}

-(BOOL) cleanupOnCancel{
    return true;
}

-(void) completed {
    if(self.delegate != nil){
        [self.delegate downloadFileViewController:self downloadedFile:true withError:nil];
    }
}

-(void) failureWithError: (NSString *) error{
    if(self.delegate != nil && ![error isEqualToString:@"Operation was canceled"]){
        [self.delegate downloadFileViewController:self downloadedFile:false withError:error];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


#pragma mark- UITextFieldDelegate methods
- (void) textFieldDidEndEditing:(UITextField *)textField {
    [textField trimWhiteSpace:textField];
    
    if (textField == self.urlTextField) {
        NSLog(@"URL Field ended editing");
        [self validateURLField];
    } else {
        if ([self.nameTextField.text isEqualToString:@""] || [self.urlTextField.text isEqualToString:@""]) {
            [GPKGSUtils disableButton:self.importButton];
            [self.downloadedLabel setText:@"Check your GeoPackage's name and URL"];
            self.downloadedLabel.hidden = NO;
        } else {
            [GPKGSUtils enableButton:self.importButton];
            [self.downloadedLabel setText:@""];
            self.downloadedLabel.hidden = YES;
        }
    }
    
    [textField resignFirstResponder];
}


- (void) validateURLField {
    [self.urlTextField isValidGeoPackageURL:self.urlTextField withResult:^(BOOL isValid) {
        if (isValid) {
            NSLog(@"Valid URL");
            dispatch_async(dispatch_get_main_queue(), ^{
                self.urlTextField.borderStyle = UITextBorderStyleRoundedRect;
                self.urlTextField.layer.cornerRadius = 4;
                self.urlTextField.layer.borderColor = [[UIColor colorWithRed:0.79 green:0.8 blue:0.8 alpha:1] CGColor];
                self.urlTextField.layer.borderWidth = 0.5;
                
                [GPKGSUtils enableButton:self.importButton];
                [self.downloadedLabel setText:@""];
                self.downloadedLabel.hidden = YES;
            });
        } else {
            NSLog(@"Bad url");
            dispatch_async(dispatch_get_main_queue(), ^{
                [GPKGSUtils disableButton:self.importButton];
                
                [self.downloadedLabel setText:@"Invalid URL"];
                self.downloadedLabel.hidden = NO;
                
                self.urlTextField.borderStyle = UITextBorderStyleRoundedRect;
                self.urlTextField.layer.cornerRadius = 4;
                self.urlTextField.layer.borderColor = [[UIColor redColor] CGColor];
                self.urlTextField.layer.borderWidth = 2.0;
            });
        }
    }];
}


#pragma mark - Scrollview handling
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

@end
