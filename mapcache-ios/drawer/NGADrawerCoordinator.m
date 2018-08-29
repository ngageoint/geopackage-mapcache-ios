//
//  MCDrawerCoordinator.m
//  MapDrawer
//
//  Created by Tyler Burgett on 8/20/18.
//  Copyright © 2018 GeoPackage. All rights reserved.
//

#import "NGADrawerCoordinator.h"

@interface NGADrawerCoordinator ()
@property (strong, nonatomic) NSMutableArray *childCoordinators;
@property (strong, nonatomic) NSMutableArray<NGADrawerViewController *> *drawerStack;
@property (strong, nonatomic) UIViewController *backgroundViewController;
@property (nonatomic) CGFloat height;
@property (nonatomic) CGFloat width;
@end

@implementation NGADrawerCoordinator

- (instancetype) initWithBackgroundViewController:(UIViewController *) viewController {
    self = [super init];
    _backgroundViewController = viewController;
    _childCoordinators = [[NSMutableArray alloc] init];
    _drawerStack = [[NSMutableArray alloc] init];
    
    _height = self.backgroundViewController.view.frame.size.height;
    _width = self.backgroundViewController.view.frame.size.width;
    
    return self;
}


- (void) start {
    if (_drawerStack.count == 0) {
        MCGeoPackageListCoordinator *geoPackageListCoordinator = [[MCGeoPackageListCoordinator alloc] init];
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
    [_drawerStack addObject:childViewController];
    
    [self.backgroundViewController addChildViewController:childViewController];
    [self.backgroundViewController.view addSubview:childViewController.view];
    [childViewController didMoveToParentViewController:self.backgroundViewController];
    _height = self.backgroundViewController.view.frame.size.height;
    _width = self.backgroundViewController.view.frame.size.width;
    
    // The height of the screen minus the bit at the top where the map shows through
    childViewController.view.frame = CGRectMake(0, CGRectGetMaxY(self.backgroundViewController.view.frame), _width, CGRectGetMaxY(self.backgroundViewController.view.frame) - 240);
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


// TODO; move over to the GeoPackageCoordinator
//#pragma mark - MCGeoPackageListDelegate Methods
//- (void) didSelectGeoPackage:(MCGeoPackage *)geoPackage {
//    _detailsView = [[MCGeoPackageDetailsViewController alloc] initAsFullView:YES];
//    _detailsView.delegate = self;
//    _detailsView.geoPackage = geoPackage;
//    _detailsView.drawerViewDelegate = self;
//    [self pushDrawer:_detailsView];
//    [_detailsView makeFullView];
//}


@end
