//
//  GPKGSCreateLayerViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/8/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSDatabase.h"


@protocol GPKGSCreateLayerDelegate <NSObject>
- (void) newFeatureLayer;
- (void) newTileLayer;
@end


@interface GPKGSCreateLayerViewController : UIViewController
@property (weak, nonatomic) id<GPKGSCreateLayerDelegate> delegate;
@end
