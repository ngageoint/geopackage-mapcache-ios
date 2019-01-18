//
//  MCNoticeAndAttributionViewController.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/16/19.
//  Copyright © 2019 NGA. All rights reserved.
//

#import "MCNoticeAndAttributionViewController.h"

@interface MCNoticeAndAttributionViewController ()
@property (nonatomic, strong) WKWebView *webView;
@end

@implementation MCNoticeAndAttributionViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    CGRect bounds = self.view.bounds;
    CGRect insetBounds = CGRectMake(bounds.origin.x, bounds.origin.y + 32, bounds.size.width, bounds.size.height);
    
    WKWebViewConfiguration *webViewConfiguration = [[WKWebViewConfiguration alloc] init];
    self.webView = [[WKWebView alloc] initWithFrame: insetBounds configuration:webViewConfiguration];
    self.webView.navigationDelegate = self;
    
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"privacypolicy/index" withExtension:@"html"];
    [self.webView loadFileURL:url allowingReadAccessToURL:url];
    [self.view addSubview:self.webView];
    
    [self addDragHandle];
    [self addCloseButton];
}


- (void)closeDrawer {
    [super closeDrawer];
    [self.drawerViewDelegate popDrawer];
}


- (BOOL)gestureIsInConflict:(UIPanGestureRecognizer *) recognizer {
    CGPoint point = [recognizer locationInView:self.view];
    
    if (CGRectContainsPoint(self.webView.frame, point)) {
        return true;
    }
    
    return false;
}


#pragma mark - WKNavigationDelegate methods
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (navigationAction.navigationType == WKNavigationTypeLinkActivated) {
        if (navigationAction.request.URL) {
            decisionHandler(WKNavigationActionPolicyCancel);
            [UIApplication.sharedApplication openURL:navigationAction.request.URL options:@{} completionHandler:nil];
        }
    } else {
        decisionHandler(WKNavigationActionPolicyAllow);
    }
}


@end
