//
//  MCBottomDrawerViewController.h
//  MapDrawer
//
//  Created by Tyler Burgett on 8/20/18.
//  Copyright © 2018 GeoPackage. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol NGADrawerViewDelegate <NSObject>
- (void) drawerAddAnimationComplete: (UIViewController *) viewController;
- (void) pushDrawer: (UIViewController *) childViewController;
- (void) popDrawer;
@end

@interface NGADrawerViewController : UIViewController
@property (weak, nonatomic) id<NGADrawerViewDelegate> drawerViewDelegate;
- (instancetype) initAsFullView: (BOOL) isFullView;
- (void) makeFullView;
- (void) removeDrawerFromSuperview;
@end
