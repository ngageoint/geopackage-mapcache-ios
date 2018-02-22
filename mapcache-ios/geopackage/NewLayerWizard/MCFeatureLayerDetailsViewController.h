//
//  GPKGSFeatureLayerDetailsViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/12/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <GPKGGeoPackageManager.h>
#import <GPKGGeoPackageFactory.h>
#import "GPKGSUtils.h"
#import "GPKGSConstants.h"
#import "GPKGProjectionConstants.h"
#import "GPKGSProperties.h"
#import "GPKGSButtonCell.h"
#import "GPKGBoundingBox.h"
#import "GPKGSDatabase.h"
#import "GPKGSDesctiptionCell.h"
#import "GPKGSSectionTitleCell.h"
#import "GPKGSFieldWithTitleCell.h"
#import "GPKGSPickerViewCell.h"
#import "GPKGSColorUtil.h"

@protocol MCFeatureLayerCreationDelegate <NSObject>
//- (void) featureLayerCreationComplete:(BOOL)layerCreated withError:(NSString *)error;
- (void) createFeatueLayerIn:(NSString *)database with:(GPKGGeometryColumns *)geometryColumns andBoundingBox:(GPKGBoundingBox *)boundingBox andSrsId:(NSNumber *) srsId;
@end

@interface MCFeatureLayerDetailsViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, GPKGSButtonCellDelegate>
@property (strong, nonatomic) GPKGSDatabase *database;
@property (weak, nonatomic) id<MCFeatureLayerCreationDelegate> delegate;
@end
