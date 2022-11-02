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

-(instancetype)init {
    NSURL *url = [[NSBundle mainBundle] URLForResource:@"privacypolicy/index" withExtension:@"html"];
    return [super initWithUrl:url.absoluteString];
}

//- (void)closeDrawer {
//    [super closeDrawer];
//    [self.drawerViewDelegate popDrawer];
//}


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
