//
//  GPKGSCreateLayerViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/8/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "GPKGSDatabase.h"
#import "NGADrawerViewController.h"


@protocol MCCreateLayerDelegate <NSObject>
- (void) newFeatureLayer;
- (void) newTileLayer;
@end


@interface MCCreateLayerViewController : NGADrawerViewController
@property (weak, nonatomic) id<MCCreateLayerDelegate> delegate;
@end
