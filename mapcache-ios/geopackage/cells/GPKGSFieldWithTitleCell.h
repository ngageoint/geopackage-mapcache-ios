//
//  GPKGSFieldWithTitleCellTableViewCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/9/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GPKGSFieldWithTitleCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *title;
@property (weak, nonatomic) IBOutlet UITextField *field;

@end
