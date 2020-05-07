//
//  MCBottomDrawerViewController.h
//  MapDrawer
//
//  Created by Tyler Burgett on 8/20/18.
//  Copyright © 2018 GeoPackage. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MCProperties.h"

@protocol NGADrawerViewDelegate <NSObject>
- (void) drawerAddAnimationComplete: (UIViewController *) viewController;
- (void) pushDrawer: (UIViewController *) childViewController;
- (void) popDrawer;
- (void) popDrawerAndHide;
- (void) showTopDrawer;
@end


@interface NGADrawerViewController : UIViewController <UIGestureRecognizerDelegate>
@property (nonatomic, strong) id<NGADrawerViewDelegate> drawerViewDelegate;
@property (nonatomic) BOOL swipeEnabled;
@property (nonatomic) BOOL isFullView;
@property (nonatomic) CGFloat openView;
@property (nonatomic) CGFloat collapsedView;
- (instancetype) initAsFullView: (BOOL) isFullView;
- (void) makeFullView;
- (void) removeDrawerFromSuperview;
- (void) addDragHandle;
- (void) addCloseButton;
- (void)addAndConstrainSubview:(UIView *) view;
- (void) closeDrawer;
- (void) drawerWasCollapsed;
- (void) drawerWasMadeFull;
- (void) slideDown;
- (BOOL)gestureIsInConflict:(UIPanGestureRecognizer *) recognizer;
- (void) panGesture:(UIPanGestureRecognizer *) recognizer;
- (void) rollUpPanGesture:(UIPanGestureRecognizer *) recognizer withScrollView:(UIScrollView *) scrollView;
@end
