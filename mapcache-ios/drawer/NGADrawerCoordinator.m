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


- (MCGeoPackageListCoordinator*) start {
    MCGeoPackageListCoordinator *geoPackageListCoordinator = NULL;
    if (_drawerStack.count == 0) {
        geoPackageListCoordinator = [[MCGeoPackageListCoordinator alloc] init];
        geoPackageListCoordinator.mcMapDelegate = self.mcMapDelegate;
        [_childCoordinators addObject:geoPackageListCoordinator];
        geoPackageListCoordinator.drawerViewDelegate = self;
        [geoPackageListCoordinator start];
    }
    
    return geoPackageListCoordinator;
}


#pragma mark - NGADrawerViewDelegate methods
/**
    Handle state once a drawer finishes it's animation.
    This hides the drawers behind the top drawer so if you swipe the view down you see the map not the next drawer down in the stack.
 */
- (void) drawerAddAnimationComplete: (NGADrawerViewController *) viewController {
    if (_drawerStack.count > 1) {
        NGADrawerViewController *currentTopDrawer = [_drawerStack objectAtIndex:_drawerStack.count -2];
        [currentTopDrawer.view setHidden:YES];
        [currentTopDrawer slideDown];
    }
}


/**
    Add a new frawer to the stack.
 */
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
    int heightFromTop = [[MCProperties getNumberValueOfProperty:@"nga_drawer_view_space_from_top"] intValue];
    childViewController.view.frame = CGRectMake(0, CGRectGetMaxY(self.backgroundViewController.view.frame), _width, CGRectGetMaxY(self.backgroundViewController.view.frame) - heightFromTop);
    [childViewController becameTopDrawer];
}


/**
    Remove the top drawer from the stack.
 */
- (void) popDrawer {
    if ([_drawerStack count] > 1) {
        NGADrawerViewController *oldTopDrawer = [_drawerStack objectAtIndex:_drawerStack.count -1];
        [_drawerStack removeLastObject];
        NGADrawerViewController *newTopDrawer = [_drawerStack objectAtIndex:_drawerStack.count -1];
        [newTopDrawer makeFullView];
        [newTopDrawer.view setHidden:NO];
        [newTopDrawer becameTopDrawer];
        [oldTopDrawer removeDrawerFromSuperview];
    }
}


/**
    Remove the top drawer from the stack and hide the new top drawer.
    Used in cases where you need to see the whole map such as the new tile layer bounding box.
 */
- (void) popDrawerAndHide {
    if ([_drawerStack count] > 1) {
        NGADrawerViewController *oldTopDrawer = [_drawerStack objectAtIndex:_drawerStack.count -1];
        [_drawerStack removeLastObject];
        NGADrawerViewController *newTopDrawer = [_drawerStack objectAtIndex:_drawerStack.count -1];
        [newTopDrawer makeFullView];
        [newTopDrawer becameTopDrawer];
        [newTopDrawer.view setHidden:YES];
        [oldTopDrawer removeDrawerFromSuperview];
    }
}


/**
    Set the top drawer to be visible and animate it to show it's full view.
 */
- (void) showTopDrawer {
    if ([_drawerStack count] > 1) {
        NGADrawerViewController *topDrawer = [_drawerStack objectAtIndex:_drawerStack.count - 1];
        [topDrawer makeFullView];
        [topDrawer becameTopDrawer];
        [topDrawer.view setHidden:NO];
    }
}


/**
    Get the top drawer of the drawer stack.
 */
- (NGADrawerViewController *)topDrawer {
    if (self.drawerStack.count > 0) {
        return [self.drawerStack objectAtIndex:self.drawerStack.count -1];
    }
    
    return nil;
}

@end
