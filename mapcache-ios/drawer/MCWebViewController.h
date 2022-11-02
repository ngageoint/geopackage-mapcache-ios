//
//  MCWebViewController.h
//  mapcache-ios
//
//  Created by Brandon Cleveland on 11/2/22.
//  Copyright © 2022 NGA. All rights reserved.
//

#ifndef MCWebViewController_h
#define MCWebViewController_h

#import "NGADrawerViewController.h"
#import <WebKit/WebKit.h>

@interface MCWebViewController : UIViewController <WKNavigationDelegate>

- (instancetype)initWithUrl: (NSString *) model;

@end

#endif /* MCWebViewController_h */
