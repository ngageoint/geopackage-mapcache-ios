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
#import "SFPProjectionConstants.h"
#import "GPKGSProperties.h"
#import "MCButtonCell.h"
#import "GPKGBoundingBox.h"
#import "GPKGSDatabase.h"
#import "MCDesctiptionCell.h"
#import "MCSectionTitleCell.h"
#import "MCFieldWithTitleCell.h"
#import "MCPickerViewCell.h"
#import "MCColorUtil.h"

@protocol MCFeatureLayerCreationDelegate <NSObject>
//- (void) featureLayerCreationComplete:(BOOL)layerCreated withError:(NSString *)error;
- (void) createFeatueLayerIn:(NSString *)database with:(GPKGGeometryColumns *)geometryColumns andBoundingBox:(GPKGBoundingBox *)boundingBox andSrsId:(NSNumber *) srsId;
@end

@interface MCFeatureLayerDetailsViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, GPKGSButtonCellDelegate>
@property (strong, nonatomic) GPKGSDatabase *database;
@property (weak, nonatomic) id<MCFeatureLayerCreationDelegate> delegate;
@end
