//
//  GPKGSHeaderCellTableViewCell.h
//  mapcache-ios
//
//  Created by Tyler Burgett on 11/17/17.
//  Copyright © 2017 NGA. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "GPKGResultSet.h"
#import "GPKGFeatureRow.h"
#import "GPKGFeatureDao.h"
#import "SFGeometry.h"
#import "GPKGMapShape.h"
#import "GPKGMapShapeConverter.h"

@interface MCHeaderCell : UITableViewCell <MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet UILabel *nameLabel;
@property (weak, nonatomic) IBOutlet UILabel *detailLabelOne;
@property (weak, nonatomic) IBOutlet UILabel *detailLabelTwo;
@property (weak, nonatomic) IBOutlet UILabel *detailLabelThree;
@property (weak, nonatomic) IBOutlet MKMapView *mapView;
@property (strong, nonatomic) MKTileOverlay *tileOverlay;
@property (strong, nonatomic) GPKGFeatureDao *featureDao;
@end
