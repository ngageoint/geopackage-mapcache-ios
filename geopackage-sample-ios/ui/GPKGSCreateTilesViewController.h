//
//  GPKGSCreateTilesViewController.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/23/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSCreateTilesData.h"
#import "GPKGSLoadTilesViewController.h"

@interface GPKGSCreateTilesViewController : UIViewController <GPKGSLoadTilesDelegate>

@property (weak, nonatomic) IBOutlet UITextField *nameTextField;
@property (nonatomic, strong) GPKGSCreateTilesData * data;

@end
