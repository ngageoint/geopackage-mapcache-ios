//
//  MCDrawerCoordinator.m
//  MapDrawer
//
//  Created by Tyler Burgett on 8/20/18.
//  Copyright © 2018 GeoPackage. All rights reserved.
//

#import "NGADrawerCoordinator.h"

@interface NGADrawerCoordinator ()
@property (nonatomic, strong) NSMutableArray *childCoordinators;
@property (nonatomic, strong) NSMutableArray<NGADrawerViewController *> *drawerStack;
@property (nonatomic, strong) UIViewController *backgroundViewController;
@property (nonatomic) CGFloat height;
@property (nonatomic) CGFloat width;
@end

@implementation NGADrawerCoordinator

- (instancetype) initWithBackgroundViewController:(UIViewController *) viewController andMCMapDelegate:(id<MCMapDelegate>) mcMapDelegate {
    self = [super init];
    _backgroundViewController = viewController;
    _mcMapDelegate = mcMapDelegate;
    _childCoordinators = [[NSMutableArray alloc] init];
    _drawerStack = [[NSMutableArray alloc] init];
    
    _height = self.backgroundViewController.view.frame.size.height;
    _width = self.backgroundViewController.view.frame.size.width;
    
    return self;
}


- (void) start {
    if (_drawerStack.count == 0) {
        MCGeoPackageListCoordinator *geoPackageListCoordinator = [[MCGeoPackageListCoordinator alloc] init];
        geoPackageListCoordinator.mcMapDelegate = self.mcMapDelegate;
        [_childCoordinators addObject:geoPackageListCoordinator];
        geoPackageListCoordinator.drawerViewDelegate = self;
        [geoPackageListCoordinator start];
    }
}


#pragma mark - NGADrawerViewDelegate methods
- (void) drawerAddAnimationComplete: (NGADrawerViewController *) viewController {
    if (_drawerStack.count > 1) {
        NGADrawerViewController *currentTopDrawer = [_drawerStack objectAtIndex:_drawerStack.count -2];
        [currentTopDrawer.view setHidden:YES];
    }
}


- (void) pushDrawer:(NGADrawerViewController *) childViewController {
    if ([_drawerStack count] > 0) {
        NGADrawerViewController *drawer = [_drawerStack lastObject];
        [drawer.view setHidden:YES];
    }
    
    [_drawerStack addObject:childViewController];
    
    [self.backgroundViewController addChildViewController:childViewController];
    [self.backgroundViewController.view addSubview:childViewController.view];
    [childViewController didMoveToParentViewController:self.backgroundViewController];
    _height = self.backgroundViewController.view.frame.size.height;
    _width = self.backgroundViewController.view.frame.size.width;
    
    // The height of the screen minus the bit at the top where the map shows through
    childViewController.view.frame = CGRectMake(0, CGRectGetMaxY(self.backgroundViewController.view.frame), _width, CGRectGetMaxY(self.backgroundViewController.view.frame) - 170);
}



- (void) popDrawer {
    if ([_drawerStack count] > 1) {
        NGADrawerViewController *oldTopDrawer = [_drawerStack objectAtIndex:_drawerStack.count -1];
        [_drawerStack removeLastObject];
        NGADrawerViewController *newTopDrawer = [_drawerStack objectAtIndex:_drawerStack.count -1];
        [newTopDrawer.view setHidden:NO];
        [oldTopDrawer removeDrawerFromSuperview];
    }
}

@end
