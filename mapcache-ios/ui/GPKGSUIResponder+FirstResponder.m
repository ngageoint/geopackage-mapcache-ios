//
//  GPKGSUIResponder+FirstResponder.m
//  mapcache-ios
//
//  Created by Dan Barela on 2/17/15.
//  Created by Brian Osborn on 7/22/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSUIResponder+FirstResponder.h"

static __weak id currentFirstResponder;

@implementation UIResponder (FirstResponder)

+(id)currentFirstResponder {
    currentFirstResponder = nil;
    [[UIApplication sharedApplication] sendAction:@selector(findFirstResponder:) to:nil from:nil forEvent:nil];
    return currentFirstResponder;
}

-(void)findFirstResponder:(id)sender {
    currentFirstResponder = self;
}

@end
