//
//  MCDrawingCoordinator.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 2/20/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "MCDrawingCoordinator.h"

@interface MCDrawingCoordinator()
@property (nonatomic, strong) MCDrawingStatusViewController *drawingStatusViewController;

@end


@implementation MCDrawingCoordinator

- (instancetype) initWithDrawerDelegate:(id<NGADrawerViewDelegate>) drawerDelegate {
    self = [super init];
    _drawerDelegate = drawerDelegate;
    
    return self;
}


- (void) start {
    _drawingStatusViewController = [[MCDrawingStatusViewController alloc] init];
    _drawingStatusViewController.drawerViewDelegate = self.drawerDelegate;
    [_drawerDelegate pushDrawer:_drawingStatusViewController];
}

@end

