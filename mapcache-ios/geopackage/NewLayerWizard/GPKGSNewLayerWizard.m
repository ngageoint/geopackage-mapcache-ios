//
//  GPKGSNewLayerViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/4/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "GPKGSNewLayerWizard.h"

@interface GPKGSNewLayerWizard()
@property (strong, nonatomic) NSMutableArray *pages;
@property (strong, nonatomic) GPKGSCreateLayerViewController *createLayerViewController;
@property (nonatomic, strong) GPKGSCreateTilesData * tileData;
@end

@implementation GPKGSNewLayerWizard

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
    featureDetailsController.database = _database;
    featureDetailsController.delegate = _featureLayerDelegate;
    
    [_pages addObject:featureDetailsController];
    [self setViewControllers:@[featureDetailsController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}


- (void) newTileLayer {
    NSLog(@"Adding new tile layer");
    _tileData = [[GPKGSCreateTilesData alloc] init];
    
    GPKGSTileLayerDetailsViewController *tileDetailsController = [[GPKGSTileLayerDetailsViewController alloc] init];
    tileDetailsController.delegate = self;
    
    [_pages addObject: tileDetailsController];
    [self setViewControllers:@[tileDetailsController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}


#pragma mark - MCTileLayerDetailsDelegate methods
- (void) tileLayerDetailsCompletionHandlerWithName:(NSString *)name URL:(NSString *) url andReferenceSystemCode:(int)referenceCode {
    NSLog(@"Building bounding box view");
    _tileData.name = name;
    _tileData.loadTiles.url = url;
    _tileData.loadTiles.epsg = referenceCode;
    
    MCBoundingBoxViewController *boundingBoxViewController = [[MCBoundingBoxViewController alloc] init];
    boundingBoxViewController.delegate = self;
    
    [_pages addObject:boundingBoxViewController];
    [self setViewControllers:@[boundingBoxViewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}


#pragma mark- MCBoundingBoxDelegate methods
- (void) boundingBoxCompletionHandler:(GPKGBoundingBox *)boundingBox  {
    _tileData.loadTiles.generateTiles.boundingBox = boundingBox;
    
    MCZoomAndQualityViewController *zoomAndQualityViewController = [[MCZoomAndQualityViewController alloc] init];
    zoomAndQualityViewController.delegate = self;
    
    [_pages addObject:zoomAndQualityViewController];
    [self setViewControllers:@[zoomAndQualityViewController] direction:UIPageViewControllerNavigationDirectionForward animated:NO completion:nil];
}


#pragma mark- MCZoomAndQualityDelegate methods
- (void) zoomAndQualityCompletionHandlerWith:(NSNumber *) minZoom andMaxZoom:(NSNumber *) maxZoom {
    NSLog(@"In wizard, going to call completion handler");
    
    _tileData.loadTiles.generateTiles.minZoom = minZoom;
    _tileData.loadTiles.generateTiles.maxZoom = maxZoom;
    
    [_layerCreationDelegate createTileLayer:_tileData];
}

@end
