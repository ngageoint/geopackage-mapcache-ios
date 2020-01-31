//
//  MCCreateGeoPacakgeViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/30/20.
//  Copyright © 2020 NGA. All rights reserved.
//

#import "NGADrawerViewController.h"
#import "MCTitleCell.h"
#import "MCFieldWithTitleCell.h"
#import "MCDescriptionCell.h"
#import "MCButtonCell.h"


NS_ASSUME_NONNULL_BEGIN

@protocol MCCreateGeoPackageDelegate <NSObject>
- (BOOL) isValidGeoPackageName:(NSString *) name;
- (void) createGeoPackage:(NSString *) name;
@end


@interface MCCreateGeoPacakgeViewController : NGADrawerViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, GPKGSButtonCellDelegate>
@property (nonatomic, weak) id<MCCreateGeoPackageDelegate> createGeoPackageDelegate;
@end

NS_ASSUME_NONNULL_END
