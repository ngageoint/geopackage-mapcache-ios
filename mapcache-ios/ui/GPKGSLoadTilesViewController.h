//
//  GPKGSLoadTilesViewController.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/23/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSLoadTilesData.h"

@class GPKGSLoadTilesViewController;

@protocol GPKGSLoadTilesDelegate <NSObject>
- (void)loadTilesViewControllerUrlName:(NSString *) urlName;
@end

@interface GPKGSLoadTilesViewController : UIViewController

@property (nonatomic, weak) id <GPKGSLoadTilesDelegate> delegate;
@property (weak, nonatomic) IBOutlet UITextField *urlTextField;
@property (weak, nonatomic) IBOutlet UITextField *epsgTextField;
@property (nonatomic, strong) GPKGSLoadTilesData * data;

@end
