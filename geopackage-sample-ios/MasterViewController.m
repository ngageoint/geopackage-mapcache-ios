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
#import "WKBGeometryPrinter.h"

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
        
        GPKGFeatureDao * featureDao = [self.geoPackage getFeatureDaoWithGeometryColumns:geomColumn];
        GPKGResultSet * featureResults = [featureDao queryForAll];
        int count = [featureResults count];
        for(int i = 0; i < count; i++){
            [featureResults moveToNext];
            GPKGFeatureRow * featureRow = [featureDao getFeatureRow:featureResults];
            int geomColumnIndex = [featureRow getGeometryColumnIndex];
            GPKGFeatureColumn * geomColumn = [featureRow getGeometryColumn];
            GPKGGeometryData * geomData = [featureRow getGeometry];
            
            [resultString appendString:@"\n"];
            for(NSString * column in featureDao.columns){
                GPKGFeatureColumn * userColumn = (GPKGFeatureColumn *)[featureRow getColumnWithColumnName:column];
                NSObject * value = [featureRow getValueWithColumnName:column];
                if(![userColumn isGeometry]){
                    [resultString appendFormat:@"\n%@: %@", column, value];
                }
            }
            if(geomData != nil){
                [resultString appendString:@"\n\nGeom:"];
                [resultString appendFormat:@"\nExtended: %d", geomData.extended];
                [resultString appendFormat:@"\nEmpty: %d", geomData.empty];
                [resultString appendFormat:@"\nByte Order: %ld", geomData.byteOrder];
                [resultString appendFormat:@"\nSRS Id: %@", geomData.srsId];
                if(geomData.envelope != nil){
                    [resultString appendFormat:@"\nmin x: %@", geomData.envelope.minX];
                    [resultString appendFormat:@"\nmax x: %@", geomData.envelope.maxX];
                    [resultString appendFormat:@"\nmin y: %@", geomData.envelope.minY];
                    [resultString appendFormat:@"\nmax y: %@", geomData.envelope.maxY];
                    if(geomData.envelope.hasZ){
                        [resultString appendFormat:@"\nmin z: %@", geomData.envelope.minZ];
                        [resultString appendFormat:@"\nmax z: %@", geomData.envelope.maxZ];
                    }
                    if(geomData.envelope.hasM){
                        [resultString appendFormat:@"\nmin m: %@", geomData.envelope.minM];
                        [resultString appendFormat:@"\nmax m: %@", geomData.envelope.maxM];
                    }
                }
                [resultString appendFormat:@"\nWKB Index: %d", geomData.wkbGeometryIndex];
                if(geomData.geometry != nil){
                    [resultString appendFormat:@"\nGeometry Type Code: %u", geomData.geometry.geometryType];
                    [resultString appendFormat:@"\nGeometry Type Name: %@", [WKBGeometryTypes name:geomData.geometry.geometryType]];
                    [resultString appendFormat:@"\n%@", [WKBGeometryPrinter getGeometryString:geomData.geometry]];
                }
                
                GPKGFeatureRow * newRow =[featureDao newRow];
                [newRow setGeometry:geomData];
                
                for(NSString * column in featureDao.columns){
                    GPKGFeatureColumn * userColumn = (GPKGFeatureColumn *)[featureRow getColumnWithColumnName:column];
                    if(![userColumn isGeometry] && !userColumn.primaryKey){
                        NSObject * value = [featureRow getValueWithColumnName:column];
                        [newRow setValueWithColumnName:userColumn.name andValue:value];
                        
                        enum GPKGDataType dataType = userColumn.dataType;
                        if(dataType == GPKG_DT_DATE || dataType == GPKG_DT_DATETIME){
                            NSDate * date = [NSDate date];
                            [newRow setValueWithColumnName:userColumn.name andValue:date];
                        }
                    }
                }
                
                long long newRowId = [featureDao create:newRow];
                GPKGFeatureRow * newFeatureRow = (GPKGFeatureRow *)[featureDao queryForIdObject:[NSNumber numberWithLongLong:newRowId]];
                GPKGGeometryData * newGeomData = [newFeatureRow getGeometry];
                if(newGeomData != nil){
                    if(newGeomData.geometry != nil){
                        NSString * printedGeometry = [WKBGeometryPrinter getGeometryString:newGeomData.geometry];
                        [resultString appendFormat:@"\nSaved Geometry Type Code: %u", newGeomData.geometry.geometryType];
                        [resultString appendFormat:@"\nSaved Geometry Type Name: %@", [WKBGeometryTypes name:newGeomData.geometry.geometryType]];
                        [resultString appendFormat:@"\n%@", printedGeometry];
                    }
                }
            } 
        }
        [featureResults close];
    }
    [allGeometryColumns close];
    
    NSArray *idValues = @[@"multipoint2d", @"geom"];
    GPKGGeometryColumns *idValuesResult = (GPKGGeometryColumns *)[dao queryForMultiIdObject:idValues];
    
    GPKGGeometryColumns *idValueResult = (GPKGGeometryColumns *)[dao queryForIdObject:@"linestring2d"];
    
    GPKGResultSet *equalResult = [dao queryForEqWithField:GPKG_GC_COLUMN_Z andValue: [NSNumber numberWithInt:1]];
    while([equalResult moveToNext]){
        GPKGGeometryColumns *geomColumn = (GPKGGeometryColumns *)[dao getObject: equalResult];
    }
    [equalResult close];
    
    int count = [dao count];
    int count2 = [dao countWhere:[NSString stringWithFormat:@"%@ = 'linestring2d'", GPKG_GC_COLUMN_TABLE_NAME]];
    
    GPKGColumnValues *columnValues = [[GPKGColumnValues alloc] init];
    GPKGColumnValue *tableNameCV = [[GPKGColumnValue alloc] init];
    tableNameCV.value = @"linestring3d";
    [columnValues addColumn:GPKG_GC_COLUMN_TABLE_NAME withValue:tableNameCV];
    GPKGColumnValue *zCV = [[GPKGColumnValue alloc] init];
    zCV.value = [NSNumber numberWithInt:1];
    zCV.tolerance = [NSNumber numberWithDouble:0.5];
    [columnValues addColumn:GPKG_GC_COLUMN_Z withValue:zCV];

    GPKGResultSet *dictionaryResult = [dao queryForColumnValueFieldValues:columnValues];
    GPKGGeometryColumns *geomColumn = nil;
    while([dictionaryResult moveToNext]){
        geomColumn = (GPKGGeometryColumns *)[dao getObject: dictionaryResult];
    }
    [dictionaryResult close];
    
    geomColumn.geometryTypeName = @"POINT";
    geomColumn.m = [NSNumber numberWithInt:1];
    int updated = [dao update:geomColumn];
    
    idValues = [dao getMultiId:geomColumn];
    GPKGGeometryColumns *geomColumn2 = (GPKGGeometryColumns *)[dao queryForMultiIdObject:idValues];
    int deleted = [dao delete:geomColumn2];
    geomColumn2 = (GPKGGeometryColumns *)[dao queryForMultiIdObject:idValues];
    
    allGeometryColumns = [dao queryForAll];
    [resultString appendString:@"\n\n"];
    [resultString appendFormat:@"New Count: %d", allGeometryColumns.count];
    [allGeometryColumns close];
    
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
    [allGeometryColumns close];
    
    self.resultText.text = resultString;
    
    [dao dropTable];
    
    tableExists = [dao tableExists];
    
}

@end
