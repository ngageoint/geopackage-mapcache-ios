//
//  GPKGSLinkedTablesViewController.h
//  mapcache-ios
//
//  Created by Brian Osborn on 2/8/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSTable.h"
#import "GPKGGeoPackageManager.h"

@class GPKGSLinkedTablesViewController;

@protocol GPKGSLinkedTablesDelegate <NSObject>
- (void)linkedTablesViewController:(GPKGSLinkedTablesViewController *)controller linksEdited:(BOOL)edited withError: (NSString *) error;
@end

@interface GPKGSLinkedTablesViewController : UIViewController<UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, weak) id <GPKGSLinkedTablesDelegate> delegate;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGSTable *table;

@end
