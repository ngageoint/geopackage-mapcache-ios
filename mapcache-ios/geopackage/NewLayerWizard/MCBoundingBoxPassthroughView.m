//
//  MCBoundingBoxPassthroughView.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 9/17/19.
//  Copyright © 2019 NGA. All rights reserved.
//

#import "MCBoundingBoxPassthroughView.h"

@implementation MCBoundingBoxPassthroughView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

- (UIView *) hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *view = [super hitTest:point withEvent:event];
    
    return view == self ? nil : view;
}

@end
