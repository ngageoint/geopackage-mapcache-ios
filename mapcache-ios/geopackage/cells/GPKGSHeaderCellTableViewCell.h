//
//  GPKGSHeaderCellTableViewCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/17/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GPKGSHeaderCellButtonPressedDelegate <NSObject>
- (void) deleteGeoPackage;
- (void) shareGeoPackage;
- (void) renameGeoPackage;
@end

@interface GPKGSHeaderCellTableViewCell : UITableViewCell
@property (weak, nonatomic) id<GPKGSHeaderCellButtonPressedDelegate> delegate;

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *tileCountLabel;
@property (weak, nonatomic) IBOutlet UILabel *featureCountLabel;
@end
