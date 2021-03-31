//
//  GPKGSDesctiptionCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/10/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MCDescriptionCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *descriptionLabel;
- (void) setDescription: (NSString *) description;
- (void)textAlignCenter;
- (void)textAlignRight;
- (void)textAlignLeft;
- (void)useSecondaryAppearance;
@end
 
