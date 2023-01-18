//
//  SlowServerModel.m
//  mapcache-ios
//
//  Created by Brandon Cleveland on 9/27/22.
//  Copyright © 2022 NGA. All rights reserved.
//

#import "SlowServerModel.h"

@interface SlowServerModel ()

@property (nonatomic, strong) NSString *slowMessage;

@end

@implementation SlowServerModel

-(NSString *) getMessage{
    return self.slowMessage;
}

-(void) setMessage:(NSString *)newMessage {
    self.slowMessage = newMessage;
}

@end
