//
//  GPKGSDisplayTextViewController.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSTable.h"
#import "GPKGSDatabase.h"
#import <GPKGMapPoint.h>

@interface GPKGSDisplayTextViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIButton *titleButton;
@property (weak, nonatomic) IBOutlet UITextView *textView;
@property (nonatomic, strong) GPKGMapPoint *mapPoint;
@property (nonatomic, strong) GPKGSDatabase * database;
@property (nonatomic, strong) GPKGSTable * table;

@end
