//
//  MasterViewController.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 5/5/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "MasterViewController.h"
#import "GPKGGeoPackage.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGGeoPackageManager.h"
#import "GPKGGeometryColumnsDao.h"


@interface MasterViewController ()

@property (nonatomic, strong) GPKGGeoPackage *geoPackage;

@end

@implementation MasterViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GPKGGeoPackageManager *manager = [GPKGGeoPackageFactory getManager];
    self.geoPackage = [manager open:@"TestName"];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)buttonTapped:(id)sender {
    
    NSMutableString *resultString = [NSMutableString string];
    
    /*
    // Prepare the query string.
    NSString *query = @"select * from gpkg_spatial_ref_sys";
    //NSString *query = @"select name from sqlite_master where type ='table'";
    
    // Execute the query.
    NSArray *results = [[NSArray alloc] initWithArray:[[self.geoPackage getDatabase] query:query]];
    
    [resultString appendFormat:@"Results: %lu", results.count];
    [resultString appendString:@"\n"];
    //self.resultText.text = [NSString stringWithFormat:@"Results: %lu", results.count];
    
    for (NSMutableArray *result in results) {
        for(int i = 0; i < result.count; i++){
            NSString *value = [result objectAtIndex:(i)];
            [resultString appendString:@"\n"];
            [resultString appendString:value];
        }
    }
    
    [resultString appendString:@"\n"];
     */
    
    NSArray *featureTables = [self.geoPackage getFeatureTables];
    for (NSString *featureTable in featureTables) {
        [resultString appendString:@"\n"];
        [resultString appendString:featureTable];
    }
    
    GPKGGeometryColumnsDao *dao = [self.geoPackage getGeometryColumnsDao];
    
    BOOL tableExists = [dao isTableExists];
    [resultString appendString:@"\n"];
    [resultString appendString:@"\n"];
    [resultString appendString:[NSString stringWithFormat:@"Table Exists: %d", tableExists]];
    
    NSArray *allGeometryColumns = [dao queryForAll];
    for(GPKGGeometryColumns *geomColumn in allGeometryColumns){
        [resultString appendString:@"\n\n"];
        [resultString appendString:geomColumn.tableName];
        [resultString appendString:@"\n"];
        [resultString appendString:geomColumn.columnName];
        [resultString appendString:@"\n"];
        [resultString appendString:geomColumn.geometryTypeName];
        [resultString appendString:@"\n"];
        [resultString appendString:[geomColumn.srsId stringValue]];
        [resultString appendString:@"\n"];
        [resultString appendString:[geomColumn.z stringValue]];
        [resultString appendString:@"\n"];
        [resultString appendString:[geomColumn.m stringValue]];
    }
    
    
    self.resultText.text = resultString;
    
}

@end
