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
    
    NSArray *featureTables = [self.geoPackage getFeatureTables];
    for (NSString *featureTable in featureTables) {
        [resultString appendString:@"\n"];
        [resultString appendString:featureTable];
    }
    
    GPKGGeometryColumnsDao *dao = [self.geoPackage getGeometryColumnsDao];
    
    BOOL tableExists = [dao tableExists];
    [resultString appendString:@"\n"];
    [resultString appendString:@"\n"];
    [resultString appendFormat:@"Table Exists: %d", tableExists];
    
    GPKGResultSet *allGeometryColumns = [dao queryForAll];
    [resultString appendString:@"\n\n"];
    [resultString appendFormat:@"Count: %d", allGeometryColumns.count];
    while([allGeometryColumns moveToNext]){
        GPKGGeometryColumns *geomColumn = (GPKGGeometryColumns *)[dao getObject: allGeometryColumns];

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
    [allGeometryColumns close];
    
    NSArray *idValues = @[@"multipoint2d", @"geom"];
    GPKGGeometryColumns *idValuesResult = (GPKGGeometryColumns *)[dao queryForMultiIdObject:idValues];
    
    GPKGGeometryColumns *idValueResult = (GPKGGeometryColumns *)[dao queryForIdObject:@"linestring2d"];
    
    GPKGResultSet *equalResult = [dao queryForEqWithField:GC_COLUMN_Z andValue: [NSNumber numberWithInt:1]];
    while([equalResult moveToNext]){
        GPKGGeometryColumns *geomColumn = (GPKGGeometryColumns *)[dao getObject: equalResult];
    }
    [equalResult close];
    
    int count = [dao count];
    int count2 = [dao countWhere:[NSString stringWithFormat:@"%@ = 'linestring2d'", GC_COLUMN_TABLE_NAME]];
    
    NSMutableDictionary *dictionary = [[NSMutableDictionary alloc] init];
    GPKGColumnValue *tableNameCV = [[GPKGColumnValue alloc] init];
    tableNameCV.value = @"linestring3d";
    [dictionary setObject:tableNameCV forKey:GC_COLUMN_TABLE_NAME];
    GPKGColumnValue *zCV = [[GPKGColumnValue alloc] init];
    zCV.value = [NSNumber numberWithInt:1];
    zCV.tolerance = [NSNumber numberWithDouble:0.5];
    [dictionary setObject:zCV forKey:GC_COLUMN_Z];

    GPKGResultSet *dictionaryResult = [dao queryForColumnValueFieldValues:dictionary];
    GPKGGeometryColumns *geomColumn = nil;
    while([dictionaryResult moveToNext]){
        geomColumn = (GPKGGeometryColumns *)[dao getObject: dictionaryResult];
    }
    
    geomColumn.geometryTypeName = @"POINT";
    geomColumn.m = [NSNumber numberWithInt:1];
    int updated = [dao update:geomColumn];
    
    idValues = [dao getIdValues:geomColumn];
    GPKGGeometryColumns *geomColumn2 = (GPKGGeometryColumns *)[dao queryForMultiIdObject:idValues];
    int deleted = [dao delete:geomColumn2];
    geomColumn2 = (GPKGGeometryColumns *)[dao queryForMultiIdObject:idValues];
    
    allGeometryColumns = [dao queryForAll];
    [resultString appendString:@"\n\n"];
    [resultString appendFormat:@"New Count: %d", allGeometryColumns.count];
    
    GPKGGeometryColumns *newGeomColumns = [[GPKGGeometryColumns alloc] init];
    newGeomColumns.tableName = @"test_table";
    newGeomColumns.columnName = @"test_column";
    newGeomColumns.geometryTypeName = @"GEOMETRY";
    newGeomColumns.srsId = [NSNumber numberWithInt:0];
    newGeomColumns.z = [NSNumber numberWithInt:1];
    newGeomColumns.m = [NSNumber numberWithInt:1];
    long long newId = [dao insert:newGeomColumns];
    GPKGGeometryColumns *newGeomResult = [dao queryForTableName:newGeomColumns.tableName];
    //GPKGGeometryColumns *newGeomResult = (GPKGGeometryColumns *)[dao queryForMultiIdObject:@[@"test_table", @"test_column"]];
    
    [resultString appendString:@"\n\nNew Geom Query:\n"];
    [resultString appendString:newGeomResult.tableName];
    [resultString appendString:@"\n"];
    [resultString appendString:newGeomResult.columnName];
    [resultString appendString:@"\n"];
    [resultString appendString:newGeomResult.geometryTypeName];
    [resultString appendString:@"\n"];
    [resultString appendString:[newGeomResult.srsId stringValue]];
    [resultString appendString:@"\n"];
    [resultString appendString:[newGeomResult.z stringValue]];
    [resultString appendString:@"\n"];
    [resultString appendString:[newGeomResult.m stringValue]];
    
    allGeometryColumns = [dao queryForAll];
    [resultString appendString:@"\n\n"];
    [resultString appendFormat:@"New Count: %d", allGeometryColumns.count];
    
    self.resultText.text = resultString;
    
    [dao dropTable];
    
    tableExists = [dao tableExists];
    
}

@end
