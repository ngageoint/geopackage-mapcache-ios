//
//  GPKGSPickerViewCellTableViewCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/23/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GPKGSPickerViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UIPickerView *picker;

@end
