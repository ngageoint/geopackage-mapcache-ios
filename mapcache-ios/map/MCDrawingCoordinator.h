//
//  MCDrawingCoordinator.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/20/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MCDrawingStatusViewController.h"

NS_ASSUME_NONNULL_BEGIN

@interface MCDrawingCoordinator : NSObject
@property (nonatomic, strong) id<NGADrawerViewDelegate> drawerDelegate;
- (void) start;
@end

NS_ASSUME_NONNULL_END
