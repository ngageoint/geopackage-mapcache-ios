//
//  GPKGSNewLayerViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/4/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSTable.h"
#import "GPKGSFeatureTable.h"
#import "GPKGSTileTable.h"
#import "GPKGSDatabase.h"
#import "GPKGSCreateLayerViewController.h"

@interface GPKGSNewLayerViewController : UIPageViewController <UIPageViewControllerDelegate, UIPageViewControllerDataSource, GPKGSCreateLayerDelegate>

@end
