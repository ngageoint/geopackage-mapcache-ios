//
//  GPKGSTestViewController.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 5/5/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSTestViewController.h"
#import "GPKGGeoPackage.h"
#import "GPKGGeoPackageFactory.h"
#import "GPKGGeoPackageManager.h"
#import "GPKGGeometryColumnsDao.h"
#import "WKBGeometryPrinter.h"
#import "GPKGTableCreator.h"
#import "GPKGUrlTileGenerator.h"

@interface GPKGSTestViewController ()

@property (nonatomic, strong) GPKGGeoPackage *geoPackage;

@end

@implementation GPKGSTestViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    GPKGGeoPackageManager *manager = [GPKGGeoPackageFactory getManager];
    //[manager deleteAll];
    NSString * file = @"gdal_sample.gpkg";
    NSString * databaseName = [file stringByDeletingPathExtension];
    [manager delete:databaseName];
    NSString *filePath  = [[[NSBundle bundleForClass:[GPKGSTestViewController class]] resourcePath] stringByAppendingPathComponent:file];
    BOOL created = [manager importGeoPackageFromPath:filePath andDatabase:databaseName];
    self.geoPackage = [manager open:databaseName];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(IBAction)buttonTapped:(id)sender {
    
    NSMutableString *resultString = [NSMutableString string];
    
    GPKGGeoPackageManager *manager = [GPKGGeoPackageFactory getManager];
    BOOL exists = [manager exists:self.geoPackage.name];
    [resultString appendFormat:@"GeoPackage Exists: %d", exists];
    int size = [manager size: self.geoPackage.name];
    [resultString appendFormat:@"\nGeoPackage Size: %d", size];
    NSString * sizeString = [manager readableSize:self.geoPackage.name];
    [resultString appendFormat:@"\nGeoPackage Readable Size: %@", sizeString];
    NSString * copyName = @"temp";
    [manager copy:self.geoPackage.name to:copyName];
    BOOL copyExists = [manager exists:copyName];
    [resultString appendFormat:@"\nCopy Exists: %d", copyExists];
    NSString * copyName2 = @"another";
    [manager rename:copyName to:copyName2];
    copyExists = [manager exists:copyName];
    BOOL renameExists = [manager exists:copyName2];
    [resultString appendFormat:@"\nRename Exists: %d, Original Exists: %d", renameExists, copyExists];
    [manager delete:copyName2];
    [resultString appendString:@"\n"];
    
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
    
    [self.geoPackage createMetadataTable];
    
    [dao dropTable];
    
    tableExists = [dao tableExists];
    
    NSString * url = @"http://osm.geointapps.org/osm/{z}/{x}/{y}.png";
    GPKGUrlTileGenerator * urlTileGenerator = [[GPKGUrlTileGenerator alloc] initWithGeoPackage:self.geoPackage andTableName:@"gen_test" andTileUrl:url andMinZoom:0 andMaxZoom:1];
    int tilesGenerated = [urlTileGenerator generateTiles];
    [resultString appendString:@"\n\n"];
    [resultString appendFormat:@"Tiles Generated: %d", tilesGenerated];
    
    url = @"http://nowcoast.noaa.gov/wms/com.esri.wms.Esrimap/obs?service=wms%26version=1.1.1%26request=GetMap%26format=jpeg%26BBOX={minLon},{minLat},{maxLon},{maxLat}%26SRS=EPSG:4326%26width=256%26height=256%26Layers=world_countries,RAS_GOES,RAS_RIDGE_NEXRAD";
    GPKGUrlTileGenerator * urlTileGenerator2 = [[GPKGUrlTileGenerator alloc] initWithGeoPackage:self.geoPackage andTableName:@"gen_test2" andTileUrl:url andMinZoom:0 andMaxZoom:1];
    int tilesGenerated2 = [urlTileGenerator2 generateTiles];
    [resultString appendString:@"\n\n"];
    [resultString appendFormat:@"Tiles Generated2: %d", tilesGenerated2];
    
    self.resultText.text = resultString;
}

@end
