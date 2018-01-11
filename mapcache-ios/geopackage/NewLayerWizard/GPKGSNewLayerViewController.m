//
//  GPKGSNewLayerViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/4/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "GPKGSNewLayerViewController.h"

@interface GPKGSNewLayerViewController()
@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (strong, nonatomic) NSMutableArray *pages;
@property (strong, nonatomic) GPKGSCreateLayerViewController *createLayerViewController;
@end

@implementation GPKGSNewLayerViewController

- (void) viewDidLoad {
    _pageViewController = [[UIPageViewController alloc] init];
    _pageViewController.dataSource = self;
    _pageViewController.delegate = self;
    
    _pages = [[NSMutableArray alloc] init];
    _createLayerViewController = [[GPKGSCreateLayerViewController alloc] initWithNibName:@"CreateLayerView" bundle:nil];
    _createLayerViewController.delegate = self;
    [_pages addObject:_createLayerViewController];
    
    [_pageViewController setViewControllers:_pages direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
    [self addChildViewController:_pageViewController];
    [[self view] addSubview:[_pageViewController view]];
    [_pageViewController didMoveToParentViewController:self];
}


#pragma mark - PageViewController delegate methods
- (nullable UIViewController *)pageViewController:(nonnull UIPageViewController *)pageViewController viewControllerAfterViewController:(nonnull UIViewController *)viewController {
    NSUInteger index = [_pages indexOfObject: viewController];
    
    if (index == _pages.count) {
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
}


- (void) newTileLayer {
    NSLog(@"Adding new tile layer");
    GPKGSTileLayerDetailsViewController *tileDetailsController = [[GPKGSTileLayerDetailsViewController alloc] init];
    [_pages addObject: tileDetailsController];
    
    NSArray *page = @[_pages[[_pages indexOfObject:tileDetailsController]]];
    [_pageViewController setViewControllers:page direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}


@end
