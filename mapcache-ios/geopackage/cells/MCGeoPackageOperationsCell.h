//
//  MCGeoPackageButtonsCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 7/9/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol MCGeoPackageOperationsCellDelegate
- (void) deleteGeoPackage;
- (void) shareGeoPackage;
- (void) renameGeoPackage;
- (void) copyGeoPackage;
// TODO: Figure out a good way to show the detailed info.
@end


@interface MCGeoPackageOperationsCell : UITableViewCell
@property (strong, nonatomic) id<MCGeoPackageOperationsCellDelegate> delegate;

@property (weak, nonatomic) IBOutlet UIButton *renameButton;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *duplicateButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@end
