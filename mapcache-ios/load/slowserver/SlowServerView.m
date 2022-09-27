//
//  SlowServerView.m
//  mapcache-ios
//
//  Created by Brandon Cleveland on 9/27/22.
//  Copyright © 2022 NGA. All rights reserved.
//

#import "SlowServerView.h"

@interface SlowServerView ()

@property (nonatomic, strong) SlowServerModel* model;
@property (nonatomic, strong) UIAlertView *alertView;

@end

@implementation SlowServerView

-(id)init: (SlowServerModel *) model{
    if(self = [super init]) {
        self.model = model;
    }

    return ([NSObject init]); // return self;
}

-(void) show{

    self.alertView = [[UIAlertView alloc]
                              initWithTitle:@"Slow Downloads"
                              message:[self.model getMessage]
                              delegate:nil
                              cancelButtonTitle:@"Ok"
                              otherButtonTitles:nil];
    [self.alertView show];
}

@end
