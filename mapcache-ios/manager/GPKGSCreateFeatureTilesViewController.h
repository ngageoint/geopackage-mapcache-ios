//
//  GPKGSCreateFeatureTilesViewController.h
//  mapcache-ios
//
//  Created by Brian Osborn on 7/28/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GPKGSTable.h"
#import "GPKGGeoPackageManager.h"
#import "GPKGSGenerateTilesData.h"
#import "GPKGSFeatureTilesDrawData.h"
#import "GPKGSLoadTilesProtocol.h"

@class GPKGSCreateFeatureTilesViewController;

@protocol GPKGSCreateFeatureTilesDelegate <NSObject>
- (void)createFeatureTilesViewController:(GPKGSCreateFeatureTilesViewController *)controller createdTiles:(int)count withError: (NSString *) error;
@end

@interface GPKGSCreateFeatureTilesViewController : UIViewController <GPKGSLoadTilesProtocol>

@property (nonatomic, weak) id <GPKGSCreateFeatureTilesDelegate> delegate;
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) NSString *database;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) GPKGSGenerateTilesData *generateTilesData;
@property (nonatomic, strong) GPKGSFeatureTilesDrawData *featureTilesDrawData;
@property (weak, nonatomic) IBOutlet UILabel *warningLabel;
@property (weak, nonatomic) IBOutlet UITextField *databaseValue;
@property (weak, nonatomic) IBOutlet UITextField *nameValue;

@end
