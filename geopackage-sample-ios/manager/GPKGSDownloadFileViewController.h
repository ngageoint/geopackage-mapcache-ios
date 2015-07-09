//
//  GPKGSDownloadFileViewController.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/9/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGProgress.h"

@class GPKGSDownloadFileViewController;

@protocol GPKGSDownloadFileDelegate <NSObject>
- (void)downloadFileViewController:(GPKGSDownloadFileViewController *)controller downloadedFile:(BOOL)downloaded withError: (NSString *) error;
@end

@interface GPKGSDownloadFileViewController : UIViewController <GPKGProgress>

@property (nonatomic, weak) id <GPKGSDownloadFileDelegate> delegate;
@property (weak, nonatomic) IBOutlet UIButton *cancelButton;
@property (weak, nonatomic) IBOutlet UIButton *preloadedButton;
@property (weak, nonatomic) IBOutlet UIButton *importButton;
@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
@property (weak, nonatomic) IBOutlet UILabel *downloadedLabel;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;

@end
