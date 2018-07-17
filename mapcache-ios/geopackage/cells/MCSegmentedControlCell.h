//
//  GPKGSSegmentedControlCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/30/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>


@protocol GPKGSSegmentedControlCellDelegate <NSObject>
@end


@interface MCSegmentedControlCell : UITableViewCell
@property (weak, nonatomic) id<GPKGSSegmentedControlCellDelegate> delegate;
@property (weak, nonatomic) IBOutlet UILabel *label;
@property (weak, nonatomic) IBOutlet UISegmentedControl *segmentedControl;
@property (strong, nonatomic) NSArray *items;

- (void) setItems:(NSArray *)items;
@end
