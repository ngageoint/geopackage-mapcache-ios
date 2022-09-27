//
//  SlowServerNotifier.h
//  mapcache-ios
//
//  Created by Brandon Cleveland on 9/27/22.
//  Copyright © 2022 NGA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SlowServerNotifier : NSObject

- (void) responseTime : (NSString *) host timeInSeconds: (double) timeInSeconds;

@end
