//
//  GPKGSFeatureLayerDetailsViewController.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 1/12/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NGADrawerViewController.h"
#import <MapKit/MapKit.h>
#import <GPKGGeoPackageManager.h>
#import <GPKGGeoPackageFactory.h>
#import "MCUtils.h"
#import "MCConstants.h"
#import "PROJProjectionConstants.h"
#import "MCProperties.h"
#import "MCButtonCell.h"
#import "GPKGBoundingBox.h"
#import "MCDatabase.h"
#import "MCDescriptionCell.h"
#import "MCSectionTitleCell.h"
#import "MCFieldWithTitleCell.h"
#import "MCPickerViewCell.h"
#import "MCColorUtil.h"

@protocol MCFeatureLayerCreationDelegate <NSObject>
//- (void) featureLayerCreationComplete:(BOOL)layerCreated withError:(NSString *)error;
- (void) createFeatueLayerIn:(NSString *)database withGeomertyColumns:(GPKGGeometryColumns *)geometryColumns andBoundingBox:(GPKGBoundingBox *)boundingBox andSrsId:(NSNumber *) srsId;
@end

@interface MCFeatureLayerDetailsViewController : NGADrawerViewController <UITableViewDelegate, UITableViewDataSource, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, MCButtonCellDelegate>
@property (strong, nonatomic) MCDatabase *database;
@property (weak, nonatomic) id<MCFeatureLayerCreationDelegate> delegate;
@end
