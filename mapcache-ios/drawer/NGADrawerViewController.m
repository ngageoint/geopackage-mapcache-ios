//
//  MCBottomDrawerViewController.m
//  MapDrawer
//
//  Created by Tyler Burgett on 8/20/18.
//  Copyright © 2018 GeoPackage. All rights reserved.
//

#import "NGADrawerViewController.h"

@interface NGADrawerViewController ()
@property (nonatomic) BOOL startedAsFullView;
@property (nonatomic, strong) UIPanGestureRecognizer *panGestureRecognizer;
@property (nonatomic) CGFloat previousContentOffset; // Only used for rolled up gestures
@end


@implementation NGADrawerViewController

- (instancetype) initAsFullView: (BOOL) isFullView {
    self = [super init];
    _startedAsFullView = isFullView;
    _isFullView = YES;
    _swipeEnabled = YES;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _openView = [[MCProperties getNumberValueOfProperty:@"nga_drawer_view_space_from_top"] intValue]; // 160 or 200? Check value in Coordinator pushDrawer
    _collapsedView = [UIScreen mainScreen].bounds.size.height - 160; //120 // TODO: make this a property
    NSLog(@"Screen height: %f", [UIScreen mainScreen].bounds.size.height);
    
    _panGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
    _panGestureRecognizer.delegate = self;
    _previousContentOffset = 0;
    [self.view addGestureRecognizer:_panGestureRecognizer];
    [self roundViews];
}


- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self prepareBackgroundView];
}


- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (_startedAsFullView) {
        self.view.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, self.view.frame.size.width, self.view.frame.size.height);
        self.view.alpha = 1;
        
        [UIView animateWithDuration:0.3 animations:^{
            self.view.frame = CGRectMake(0, self.openView, self.view.frame.size.width, self.view.frame.size.height);
            self.view.alpha = 1;
        } completion:^(BOOL finished) {
            [self.drawerViewDelegate drawerAddAnimationComplete:self];
        }];
    } else {
        [UIView animateWithDuration:0.6 animations:^{
            self.view.frame = CGRectMake(0, self.collapsedView, self.view.frame.size.width, self.view.frame.size.height);
        }];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void) panGesture:(UIPanGestureRecognizer *) recognizer {
    if (![self gestureIsInConflict:recognizer] && _swipeEnabled) {
        CGPoint translation = [recognizer translationInView:self.view];
        CGPoint velocity = [recognizer velocityInView:self.view];
        CGFloat y = CGRectGetMinY(self.view.frame);
        
        if (y + translation.y > _openView && y + translation.y <= _collapsedView) {
            self.view.frame = CGRectMake(0, y + translation.y, self.view.frame.size.width, self.view.frame.size.height);
            [recognizer setTranslation:CGPointZero inView:self.view];
        }
        
        if (recognizer.state == UIGestureRecognizerStateEnded) {
            double duration = velocity.y < 0 ? ((y - _openView) / -velocity.y) : ((_collapsedView - y) / velocity.y);
            duration = duration > 1.3 ? 1 : duration;
            
            [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
                if (velocity.y >= 0) {
                    self.view.frame = CGRectMake(0, self.collapsedView, self.view.frame.size.width, self.view.frame.size.height);
                    self.isFullView = NO;
                    [self drawerWasCollapsed];
                } else {
                    self.view.frame = CGRectMake(0, self.openView, self.view.frame.size.width, self.view.frame.size.height);
                    self.isFullView = YES;
                    [self drawerWasMadeFull];
                }
            } completion:nil];
        }
    }
}


/**
    Called from a child class that contains a scrollview or tableview when the delegate method scrollViewDidScroll is called.
    This method checks the state of of the scrollview. If it is at the top and is dragged down, then the swipe event is handled
    at the drawer causing it to collapse. Likewise if the drawer is collapsed and a swipe up is detected, rather than scroll the
    view the drawer will be set to its full view.
 */
- (void) rollUpPanGesture:(UIPanGestureRecognizer *) recognizer withScrollView:(UIScrollView *) scrollView {
    CGPoint velocity = [scrollView.panGestureRecognizer velocityInView:self.view];
    CGFloat y = CGRectGetMinY(self.view.frame);
    double duration = velocity.y < 0? ((y - self.openView) / -velocity.y) : ((self.collapsedView - y) / velocity.y);
    duration = duration > 1.3 ? 0.65 : duration;
    
    if (scrollView.contentOffset.y < 0  && self.previousContentOffset == 0) {
        self.previousContentOffset = scrollView.contentOffset.y;
        scrollView.scrollEnabled = NO;
        [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            if (velocity.y >= 0) {
                self.view.frame = CGRectMake(0, self.collapsedView, self.view.frame.size.width, self.view.frame.size.height);
            }
        } completion:^(BOOL finished) {
            self.isFullView = NO;
            scrollView.scrollEnabled = YES;
            [self drawerWasCollapsed];
        }];
        
        
    } else if (scrollView.contentOffset.y > 0 && !self.isFullView) {
        self.previousContentOffset = scrollView.contentOffset.y;
        [UIView animateWithDuration:duration delay:0.0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            if (velocity.y >= 0) {
                self.view.frame = CGRectMake(0, self.openView, self.view.frame.size.width, self.view.frame.size.height);
            }
        } completion:^(BOOL finished) {
            scrollView.scrollEnabled = YES;
            self.isFullView = YES;
            [self drawerWasMadeFull];
        }];
    }
    
    self.previousContentOffset = scrollView.contentOffset.y;
}


- (BOOL)gestureIsInConflict:(UIPanGestureRecognizer *) recognizer {
    return false;
}


- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}


/**
    Deconflict gestures, useful for nesting a tableview in the drawer and gracefully handling the swipe events..
 */
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([otherGestureRecognizer.view isKindOfClass:UITableView.class]) {
        return true;
    }
    
    NSLog(@"Checking those recognizers");
    return false;
}


/**
    Make the drawer its full height, minus the offset at the top of the screen that allows the background view to be seen.
 */
- (void) makeFullView {
    self.view.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, self.view.frame.size.width, self.view.frame.size.height);
    self.view.alpha = 0;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.view.frame = CGRectMake(0, self.openView, self.view.frame.size.width, self.view.frame.size.height);
        self.view.alpha = 1;
    } completion:^(BOOL finished) {
        [self.drawerViewDelegate drawerAddAnimationComplete:self];
    }];
    
    self.isFullView = YES;
    [self drawerWasMadeFull];
    [_drawerViewDelegate drawerAddAnimationComplete:self];
}


/**
    Collapse the drawer.
 */
- (void) slideDown {
    [UIView animateWithDuration:0.3 animations:^{
        self.view.frame = CGRectMake(0, self.collapsedView, self.view.frame.size.width, self.view.frame.size.height);
        [self drawerWasCollapsed];
        self.isFullView = NO;
    }];
}


- (void) removeDrawerFromSuperview {
    [UIView animateWithDuration:0.37 delay:0.0 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.view.frame = CGRectMake(0, [UIScreen mainScreen].bounds.size.height, self.view.frame.size.width, self.view.frame.size.height);
        self.view.alpha = 0.0;
    } completion:^(BOOL finished){
        [self removeFromParentViewController];
        [self.view removeFromSuperview];
    }];
}


/**
    Add a drag handle to the top of the drawer.
 */
- (void) addDragHandle {
    // Taking the width of the drag handle into account when adding it.
    UIImageView *dragHandle = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - 36)/2, 8, 36, 4)];
    dragHandle.image = [UIImage imageNamed:@"dragHandle"];
    UIView *handleHolder = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 16)];
    [handleHolder addSubview:dragHandle];
    [self.view addSubview:handleHolder];
}


/**
    Add a close button to the top right corner of the drawer.
 */
- (void) addCloseButton {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    [button addTarget:self
               action:@selector(closeDrawer)
     forControlEvents:UIControlEventTouchUpInside];
    [button setImage:[UIImage imageNamed:@"closeButton"] forState:UIControlStateNormal];
    button.frame = CGRectMake(self.view.frame.size.width - 36, 8, 32, 32);
    [self.view addSubview:button];
}


- (void) pushOntoStack {
    [self.drawerViewDelegate pushDrawer:self];
}


/**
    Called when the close button is pressed. Override in subclasses to perform any work needed before removing the drwer from the stack.
 */
- (void) closeDrawer {
    NSLog(@"Close button tapped.");
}


/**
    Called when the drawer is collapesed. Override in children classes to manage the state of the components in the drawer.
 */
- (void) drawerWasCollapsed {
    NSLog(@"Drawer collapsed");
}


/**
   Called when the drawer is swiped up. Override in children classes to manage the state of the components in the drawer.
*/
- (void) drawerWasMadeFull {
    NSLog(@"Drawer made full view");
}


/**
    Called when the drawer becomes the top drawer in the stack. Override in child classes to perform any setup or set state specific to becoming the top drawer.
 */
- (void) becameTopDrawer {
    
}


/**
    Round the top corners of the drawer.
 */
- (void) roundViews {
    self.view.layer.cornerRadius = 5;
    self.view.clipsToBounds = YES;
    
    [self.view.layer setBorderColor:[UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:0.25].CGColor];
    [self.view.layer setBorderWidth:1.0];
}


- (void)addAndConstrainSubview:(UIView *) view {
    [self.view addSubview:view];
    
    NSLayoutConstraint *left = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeLeft multiplier:1 constant:0];
    NSLayoutConstraint *top = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeTop multiplier:1 constant:0];
    NSLayoutConstraint *right = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeRight multiplier:1 constant:0];
    NSLayoutConstraint *bottom = [NSLayoutConstraint constraintWithItem:view attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
    
    
    [[view.topAnchor constraintEqualToAnchor:self.view.topAnchor] setActive:YES];
    [[view.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor] setActive:YES];
    [[view.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor] setActive:YES];
    [[view.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor] setActive:YES];
    view.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    
    view.frame = self.view.frame;
    
    [self.view addConstraints:@[left, top, right, bottom]];
}


- (void) prepareBackgroundView {
    // iOS 13 dark mode support
    if ([UIColor respondsToSelector:@selector(systemBackgroundColor)]) {
        self.view.backgroundColor = [UIColor colorNamed:@"ngaBackgroundColor"];
    } else {
        self.view.backgroundColor = [UIColor whiteColor];
    }
}

@end
