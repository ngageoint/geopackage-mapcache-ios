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

@interface NGADrawerViewController : UIViewController <UIGestureRecognizerDelegate>
@property (nonatomic, strong) id<NGADrawerViewDelegate> drawerViewDelegate;
@property (nonatomic) BOOL swipeEnabled;
- (instancetype) initAsFullView: (BOOL) isFullView;
- (void) makeFullView;
- (void) removeDrawerFromSuperview;
- (void) addDragHandle;
- (void) addCloseButton;
- (void) closeDrawer;
- (BOOL)gestureIsInConflict:(UIPanGestureRecognizer *) recognizer;
@end
