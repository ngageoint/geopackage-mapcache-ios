//
//  GPKGSDownloadCoordinator.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/1/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import "MCDownloadCoordinator.h"

@interface MCDownloadCoordinator()
@property (strong, nonatomic) GPKGSDownloadFileViewController *downloadViewController;
@property (strong, nonatomic) UINavigationController *navigationController;
@property (strong, nonatomic) UIBarButtonItem *backButton;
@property (strong, nonatomic) UIBarButtonItem *exampleButton;
@property (strong, nonatomic) id<GPKGSDownloadCoordinatorDelegate> delegate;
@property (nonatomic) bool didDownload;
@end


@implementation MCDownloadCoordinator

- (instancetype)initWithNavigationController:(UINavigationController *) navigationController andDelegate:(id<GPKGSDownloadCoordinatorDelegate>) delegate {
    self = [super init];
    _navigationController = navigationController;
    
    _delegate = delegate;
    _didDownload = false;
    return self;
}


- (void) start {
    _downloadViewController = [[GPKGSDownloadFileViewController alloc] initWithNibName:@"MCDownloadGeopackage" bundle:nil];
    _downloadViewController.delegate = self;
    
    _backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStyleDone target:self action:@selector(backButtonPressed)];
    [_downloadViewController.navigationItem setLeftBarButtonItem:_backButton];
    
    CATransition *transition = [CATransition animation];
    transition.duration = .5f;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
    [self.navigationController pushViewController:_downloadViewController animated:NO];
    [self.navigationController setNavigationBarHidden:NO animated:NO];
}


/* Delegate methods */
- (void)downloadFileViewController:(GPKGSDownloadFileViewController *)controller downloadedFile:(BOOL)downloaded withError: (NSString *) error{
    if(downloaded){
        [_downloadViewController dismissViewControllerAnimated:YES completion:nil];
        [_delegate downloadCoordinatorCompletitonHandler:YES];
    }
    if(error != nil){
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_IMPORT_URL_ERROR]
                                 andMessage:[NSString stringWithFormat:@"Error downloading '%@' at:\n%@\n\nError: %@", controller.nameTextField.text, controller.urlTextField.text, error]];
    }
}


- (void) backButtonPressed {
    NSLog(@"Back pressed");
    [_delegate downloadCoordinatorCompletitonHandler:_didDownload];
}

@end
