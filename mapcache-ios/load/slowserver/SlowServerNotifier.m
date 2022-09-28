//
//  SlowServerNotifier.m
//  mapcache-ios
//
//  Created by Brandon Cleveland on 9/27/22.
//  Copyright © 2022 NGA. All rights reserved.
//

#import "SlowServerNotifier.h"
#import "SlowServerModel.h"
#import "SlowServerView.h"

@interface SlowServerNotifier ()

@property (nonatomic) int slowCount;
@property (nonatomic) BOOL notified;

@end

@implementation SlowServerNotifier

-(void) responseTime:(double)timeInSeconds {
    if (timeInSeconds >= 2.0) {
        self.slowCount++;
        if (self.slowCount >= 10 && !self.notified) {
            SlowServerModel* model = [SlowServerModel alloc];
            [model setMessage:[NSString stringWithFormat:@"Downloads from %@ are taking a long time.  Either your connection is poor or the server's performance is slow.", @"host"]];
            SlowServerView* view = [[SlowServerView alloc]init: model];
            self.notified = true;
            dispatch_queue_t queue = dispatch_get_main_queue();
            dispatch_async(queue, ^{[view show];});
        }
    }
}

@end
