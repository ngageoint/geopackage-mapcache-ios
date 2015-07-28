//
//  GPKGSEditContentsViewController.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/27/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSEditContentsData.h"

@interface GPKGSEditContentsViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextField *identifierTextField;
@property (weak, nonatomic) IBOutlet UITextField *descriptionTextField;
@property (weak, nonatomic) IBOutlet UITextField *minYTextField;
@property (weak, nonatomic) IBOutlet UITextField *maxYTextField;
@property (weak, nonatomic) IBOutlet UITextField *minXTextField;
@property (weak, nonatomic) IBOutlet UITextField *maxXTextField;
@property (nonatomic, strong) GPKGSEditContentsData * data;

@end
