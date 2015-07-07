//
//  GPKGTableCell.h
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/6/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GPKGTableCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UISwitch *active;
@property (weak, nonatomic) IBOutlet UIImageView *tableType;
@property (nonatomic, strong) IBOutlet UILabel *tableName;
@property (weak, nonatomic) IBOutlet UILabel *count;

@end
