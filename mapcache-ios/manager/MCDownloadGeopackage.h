//
//  GPKGSDownloadFileViewController.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/9/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGProgress.h"
#import "NGADrawerViewController.h"
#import "UITextField+Validators.h"

@class MCDownloadGeopackage;

@protocol MCDownloadDelegate <NSObject>
- (void)downloadFileViewController:(MCDownloadGeopackage *)controller downloadedFile:(BOOL)downloaded withError: (NSString *) error;
@end

@interface MCDownloadGeopackage : NGADrawerViewController <GPKGProgress, UITextViewDelegate>

@property (nonatomic, strong) id <MCDownloadDelegate> delegate;
@property (nonatomic, strong) id<NGADrawerViewDelegate> drawerViewDelegate;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *preloadedButton;
@property (weak, nonatomic) IBOutlet UIButton *importButton;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
@property (weak, nonatomic) IBOutlet UILabel *downloadedLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end
