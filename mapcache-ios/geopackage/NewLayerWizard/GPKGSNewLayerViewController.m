//
//  GPKGSNewLayerViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/4/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "GPKGSNewLayerViewController.h"

@interface GPKGSNewLayerViewController()
@property (strong, nonatomic) NSMutableArray *pages;
@property (strong, nonatomic) GPKGSCreateLayerViewController *createLayerViewController;
@end

@implementation GPKGSNewLayerViewController

- (void) viewDidLoad {
    self.dataSource = self;
    self.delegate = self;
    
    _pages = [[NSMutableArray alloc] init];
    _createLayerViewController = [[GPKGSCreateLayerViewController alloc] initWithNibName:@"CreateLayerView" bundle:nil];
    _createLayerViewController.delegate = self;
    [_pages addObject:_createLayerViewController];
    
    [self setViewControllers:_pages direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}


#pragma mark - PageViewController delegate methods
- (nullable UIViewController *)pageViewController:(nonnull UIPageViewController *)pageViewController viewControllerAfterViewController:(nonnull UIViewController *)viewController {
    NSUInteger index = [_pages indexOfObject: viewController];
    
    if (index == _pages.count -1) {
        return nil;
    }
    
    index++;
    return [_pages objectAtIndex:index];
}


- (nullable UIViewController *)pageViewController:(nonnull UIPageViewController *)pageViewController viewControllerBeforeViewController:(nonnull UIViewController *)viewController {
    NSUInteger index = [_pages indexOfObject: viewController];
    
    if (index == 0) {
        return nil;
    }
    
    index--;
    return [_pages objectAtIndex:index];
}


- (NSInteger)presentationCountForPageViewController:(UIPageViewController *)pageViewController {
    return _pages.count;
}


#pragma mark - CreateLayerViewController delegate methods
- (void) newFeatureLayer {
    NSLog(@"Adding new feature layer");
    
    GPKGSFeatureLayerDetailsViewController *featureDetailsController = [[GPKGSFeatureLayerDetailsViewController alloc] init];
    [_pages addObject:featureDetailsController];
    
    [self setViewControllers:@[featureDetailsController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}


- (void) newTileLayer {
    NSLog(@"Adding new tile layer");
    GPKGSTileLayerDetailsViewController *tileDetailsController = [[GPKGSTileLayerDetailsViewController alloc] init];
    [_pages addObject: tileDetailsController];
    
    [self setViewControllers:@[tileDetailsController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}


@end
