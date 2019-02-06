//
//  GPKGSDownloadCoordinator.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/1/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "MCDownloadCoordinator.h"

@interface MCDownloadCoordinator()
@property (nonatomic, strong) MCDownloadGeopackage *downloadViewController;
@property (nonatomic, strong) UIBarButtonItem *backButton;
@property (nonatomic, strong) UIBarButtonItem *exampleButton;
@property (nonatomic, strong) id<GPKGSDownloadCoordinatorDelegate> downloadDelegate;
@property (nonatomic, strong) id<NGADrawerViewDelegate> drawerViewDelegate;
@property (nonatomic) bool didDownload;
@end


@implementation MCDownloadCoordinator

- (instancetype)initWithDownlaodDelegate:(id<GPKGSDownloadCoordinatorDelegate>) delegate andDrawerDelegate:(id<NGADrawerViewDelegate>)drawerDelegate {
    self = [super init];
    _downloadDelegate = delegate;
    _drawerViewDelegate = drawerDelegate;
    _didDownload = false;
    return self;
}


- (void) start {
    _downloadViewController = [[MCDownloadGeopackage alloc] initAsFullView:YES];
    _downloadViewController.delegate = self;
    _downloadViewController.drawerViewDelegate = _drawerViewDelegate;
    [_drawerViewDelegate pushDrawer:_downloadViewController];
}


/* Delegate methods */
- (void)downloadFileViewController:(MCDownloadGeopackage *)controller downloadedFile:(BOOL)downloaded withError: (NSString *) error{
    if(downloaded){
        [_downloadViewController.drawerViewDelegate popDrawer];
        [_downloadDelegate downloadCoordinatorCompletitonHandler:YES];
    }
    if(error != nil){
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_IMPORT_URL_ERROR]
                                 andMessage:[NSString stringWithFormat:@"Error downloading '%@' at:\n%@\n\nError: %@", controller.nameTextField.text, controller.urlTextField.text, error]];
    }
}


- (void) backButtonPressed {
    NSLog(@"Back pressed");
    [_downloadDelegate downloadCoordinatorCompletitonHandler:_didDownload];
}

@end
