//
//  SlowServerView.h
//  mapcache-ios
//
//  Created by Brandon Cleveland on 9/27/22.
//  Copyright © 2022 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SlowServerModel.h"

@interface SlowServerView : NSObject
 
- (instancetype)init: (SlowServerModel*) model;
- (void)show;

@end
