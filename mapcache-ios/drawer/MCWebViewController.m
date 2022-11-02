//
//  MCWebViewController.m
//  mapcache-ios
//
//  Created by Brandon Cleveland on 11/2/22.
//  Copyright © 2022 NGA. All rights reserved.
//

#import "MCWebViewController.h"

@interface MCWebViewController ()
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) NSString *urlString;
@end

@implementation MCWebViewController

-(instancetype)initWithUrl: (NSString *) url{
    if(self = [super init]) {
        self.urlString = url;
    }

    return self; // return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    CGRect bounds = self.view.bounds;
    CGRect insetBounds = CGRectMake(bounds.origin.x, bounds.origin.y, bounds.size.width, bounds.size.height); // offset on the height to account for the gap at the top of the drawer
    
    WKWebViewConfiguration *webViewConfiguration = [[WKWebViewConfiguration alloc] init];
    self.webView = [[WKWebView alloc] initWithFrame: insetBounds configuration:webViewConfiguration];
    self.webView.navigationDelegate = self;
    
    NSURL *url = [[NSURL alloc] initWithString: self.urlString];
    [self.webView loadFileURL:url allowingReadAccessToURL:url];
    [self.view addSubview:self.webView];
}

@end
