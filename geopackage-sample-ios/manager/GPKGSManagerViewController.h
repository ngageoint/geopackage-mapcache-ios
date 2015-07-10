//
//  GPKGSManagerViewController.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSDownloadFileViewController.h"

extern NSString * const GPKGS_MANAGER_SEG_DOWNLOAD_FILE;

extern const char ConstantKey;

@interface GPKGSManagerViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, GPKGSDownloadFileDelegate>

@property (weak, nonatomic) IBOutlet UIButton *clearActiveButton;

@end
