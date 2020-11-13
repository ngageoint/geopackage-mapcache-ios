//
//  GPKGSDisplayTextViewController.m
//  mapcache-ios
//
//  Created by Brian Osborn on 7/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSDisplayTextViewController.h"
#import "GPKGSMapPointData.h"
#import <GPKGGeoPackageManager.h>
#import <GPKGGeoPackageFactory.h>
#import "GPKGSUtils.h"
#import "GPKGSProperties.h"
#import "GPKGSConstants.h"
#import "SFGeometryPrinter.h"
#import "GPKGSFeatureOverlayTable.h"
#import "GPKGSchemaExtension.h"

@interface GPKGSDisplayTextViewController ()

@property (nonatomic, strong) GPKGGeoPackageManager *manager;

@end

@implementation GPKGSDisplayTextViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.manager = [GPKGGeoPackageFactory manager];
    
    if (self.mapPoint) {
        [self.titleButton setTitle:[self getTitleAndSubtitleWithMapPoint:self.mapPoint andDelimiter:@" "] forState:UIControlStateNormal];
        [self.textView setText: [self buildInfoForMapPoint:self.mapPoint]];
    } else if (self.database) {
        [self.titleButton setTitle:self.database.name forState:UIControlStateNormal];
        [self.textView setText:[self buildTextForDatabase:self.database]];
    } else if (self.table) {
        [self.textView setText:[self buildTextForTable:self.table]];
        [self.titleButton setTitle:[NSString stringWithFormat:@"%@ - %@", self.table.database, self.table.name] forState:UIControlStateNormal];
    }
}

-(NSString *) buildInfoForMapPoint: (GPKGMapPoint *) mapPoint{
    
    NSString * info = nil;
    
    GPKGSMapPointData * data = (GPKGSMapPointData *)mapPoint.data;
    switch(data.type){
        case GPKGS_MPDT_EDIT_FEATURE:
            info = [self buildInfoForExistingFeatureMapPoint:mapPoint];
            break;
        case GPKGS_MPDT_POINT:
            info = [self buildInfoForExistingFeatureMapPoint:mapPoint];
            break;
        case GPKGS_MPDT_EDIT_FEATURE_POINT:
        case GPKGS_MPDT_NEW_EDIT_POINT:
        case GPKGS_MPDT_NEW_EDIT_HOLE_POINT:
        case GPKGS_MPDT_NONE:
            info = [self buildInfoForGenericMapPoint:mapPoint];
        default:
            break;
    }
    return info;
}

-(void) addSrsToInfoString: (NSMutableString *) info withSrs: (GPKGSpatialReferenceSystem *) srs{
    [info appendFormat:@"\nSRS Name: %@", srs.srsName];
    [info appendFormat:@"\nSRS ID: %@", srs.srsId];
    [info appendFormat:@"\nOrganization: %@", srs.organization];
    [info appendFormat:@"\nCoordsys ID: %@", srs.organizationCoordsysId];
    [info appendFormat:@"\nDefinition: %@", srs.definition];
    [info appendFormat:@"\nDescription: %@", srs.theDescription];
}

-(GPKGSMapPointData *) getOrCreateDataWithMapPoint: (GPKGMapPoint *) mapPoint{
    if(mapPoint.data == nil){
        mapPoint.data = [[GPKGSMapPointData alloc] init];
    }
    return (GPKGSMapPointData *) mapPoint.data;
}

-(NSString *) buildTextForDatabase: (GPKGSDatabase *) database{
    NSMutableString * info = [[NSMutableString alloc] init];
    GPKGGeoPackage * geoPackage = [self.manager open:database.name];
    @try {
        GPKGSpatialReferenceSystemDao * srsDao = [geoPackage spatialReferenceSystemDao];
        [info appendFormat:@"Size: %@", [self.manager readableSize:database.name]];
        [info appendFormat:@"\n\nPath: %@", [self.manager pathForDatabase:database.name]];
        [info appendFormat:@"\nDocuments Path: %@", [self.manager documentsPathForDatabase:database.name]];
        [info appendFormat:@"\n\nFeature Tables: %d", [geoPackage featureTableCount]];
        [info appendFormat:@"\nTile Tables: %d", [geoPackage tileTableCount]];
        GPKGResultSet * results = [srsDao queryForAll];
        [info appendFormat:@"\nSpatial Reference Systems: %d", [results count]];
        while([results moveToNext]){
            GPKGSpatialReferenceSystem * srs = (GPKGSpatialReferenceSystem *)[srsDao object:results];
            [info appendString:@"\n"];
            [self addSrsToInfoString:info withSrs:srs];
        }
    }
    @catch (NSException *e) {
        [info appendString:[e description]];
    }
    @finally {
        [geoPackage close];
    }
    return info;
}

-(NSString *) buildTextForTable: (GPKGSTable *) table{
    NSMutableString * info = [[NSMutableString alloc] init];
    GPKGGeoPackage * geoPackage = [self.manager open:table.database];
    @try {
        NSString * tableName = table.name;
        GPKGContents * contents = nil;
        GPKGFeatureDao * featureDao = nil;
        GPKGTileDao * tileDao = nil;
        GPKGUserTable * userTable = nil;
        
        switch([table getType]){
            case GPKGS_TT_FEATURE_OVERLAY:
                tableName = ((GPKGSFeatureOverlayTable *) table).featureTable;
            case GPKGS_TT_FEATURE:
            {
                featureDao = [geoPackage featureDaoWithTableName:tableName];
                GPKGGeometryColumnsDao * geometryColumnsDao = [geoPackage geometryColumnsDao];
                contents = [geometryColumnsDao contents:featureDao.geometryColumns];
                [info appendString:@"Feature Table"];
                [info appendFormat:@"\nFeatures: %d", [featureDao count]];
                userTable = featureDao.table;
            }
                break;
            case GPKGS_TT_TILE:
            {
                tileDao = [geoPackage tileDaoWithTableName:tableName];
                GPKGTileMatrixSetDao * tileMatrixSetDao = [geoPackage tileMatrixSetDao];
                contents = [tileMatrixSetDao contents:tileDao.tileMatrixSet];
                [info appendString:@"Tile Table"];
                [info appendFormat:@"\nZoom Levels: %lu", (unsigned long)[tileDao.tileMatrices count]];
                [info appendFormat:@"\nTiles: %d", [tileDao count]];
                userTable = tileDao.table;
            }
                break;
            default:
                [NSException raise:@"Unsupported" format:@"Unsupported table type: %d", [table getType]];
        }
        
        GPKGContentsDao * contentsDao = [geoPackage contentsDao];
        GPKGSpatialReferenceSystem * srs = [contentsDao srs:contents];
        
        [info appendString:@"\n\nSpatial Reference System:"];
        [self addSrsToInfoString:info withSrs:srs];
        
        [info appendString:@"\n\nContents:"];
        [info appendFormat:@"\nTable Name: %@", contents.tableName];
        [info appendFormat:@"\nData Type: %@", contents.dataType];
        [info appendFormat:@"\nIdentifier: %@", contents.identifier];
        [info appendFormat:@"\nDescription: %@", contents.theDescription];
        [info appendFormat:@"\nLast Change: %@", contents.lastChange];
        [info appendFormat:@"\nMin X: %@", contents.minX];
        [info appendFormat:@"\nMin Y: %@", contents.minY];
        [info appendFormat:@"\nMax X: %@", contents.maxX];
        [info appendFormat:@"\nMax Y: %@", contents.maxY];
        
        if(featureDao != nil){
            GPKGGeometryColumns * geometryColumns = featureDao.geometryColumns;
            [info appendString:@"\n\nGeometry Columns:"];
            [info appendFormat:@"\nTable Name: %@", geometryColumns.tableName];
            [info appendFormat:@"\nColumn Name: %@", geometryColumns.columnName];
            [info appendFormat:@"\nGeometry Type Name: %@", geometryColumns.geometryTypeName];
            [info appendFormat:@"\nZ: %@", geometryColumns.z];
            [info appendFormat:@"\nM: %@", geometryColumns.m];
        }
        
        if(tileDao != nil){
            GPKGTileMatrixSet * tileMatrixSet = tileDao.tileMatrixSet;
            
            GPKGTileMatrixSetDao * tileMatrixSetDao = [geoPackage tileMatrixSetDao];
            GPKGSpatialReferenceSystem * tileMatrixSetSrs = [tileMatrixSetDao srs:tileMatrixSet];
            if(![tileMatrixSetSrs.srsId isEqualToNumber:srs.srsId]){
                [info appendString:@"\n\nTile Matrix Set Spatial Reference System:"];
                [self addSrsToInfoString:info withSrs:tileMatrixSetSrs];
            }
            
            [info appendString:@"\n\nTile Matrices:"];
            [info appendFormat:@"\nTable Name: %@", tileMatrixSet.tableName];
            [info appendFormat:@"\nMin X: %@", tileMatrixSet.minX];
            [info appendFormat:@"\nMin Y: %@", tileMatrixSet.minY];
            [info appendFormat:@"\nMax X: %@", tileMatrixSet.maxX];
            [info appendFormat:@"\nMax Y: %@", tileMatrixSet.maxY];
            
            [info appendFormat:@"\n\nTile Matrices:"];
            for(GPKGTileMatrix * tileMatrix in tileDao.tileMatrices){
                [info appendFormat:@"\n\nTable Name: %@", tileMatrix.tableName];
                [info appendFormat:@"\nZoom Level: %@", tileMatrix.zoomLevel];
                [info appendFormat:@"\nTiles: %d", [tileDao countWithZoomLevel:[tileMatrix.zoomLevel intValue]]];
                [info appendFormat:@"\nMatrix Width: %@", tileMatrix.matrixWidth];
                [info appendFormat:@"\nMatrix Height: %@", tileMatrix.matrixHeight];
                [info appendFormat:@"\nTile Width: %@", tileMatrix.tileWidth];
                [info appendFormat:@"\nTile Height: %@", tileMatrix.tileHeight];
                [info appendFormat:@"\nPixel X Size: %@", tileMatrix.pixelXSize];
                [info appendFormat:@"\nPixel Y Size: %@", tileMatrix.pixelYSize];
            }
        }
        
        [info appendFormat:@"\n\n%@ columns:", tableName];
        GPKGDataColumnsDao *dataColumnsDao = [[[GPKGSchemaExtension alloc] init] dataColumnsDao];
        for(GPKGUserColumn * userColumn in userTable.columns){
            [info appendFormat:@"\n\nIndex: %d", userColumn.index];
            [info appendFormat:@"\nName: %@", userColumn.name];
            if(userColumn.max != nil){
                [info appendFormat:@"\nMax: %@", userColumn.max];
            }
            [info appendFormat:@"\nNot Null: %d", userColumn.notNull];
            if(userColumn.defaultValue != nil){
                [info appendFormat:@"\nDefault Value: %@", userColumn.defaultValue];
            }
            if(userColumn.primaryKey){
                [info appendFormat:@"\nPrimary Key: %d", userColumn.primaryKey];
            }
            [info appendFormat:@"\nType: %@", userColumn.type];
            GPKGDataColumns * dataColumn = [dataColumnsDao dataColumnByTableName:tableName andColumnName:userColumn.name];
            if (dataColumn) {
                [info appendFormat: @"\nData Column Information:"];
                if ([dataColumn name]) {
                    [info appendFormat:@"\n\tName: %@", [dataColumn name]];
                }
                if ([dataColumn title]) {
                    [info appendFormat:@"\n\tTitle: %@", [dataColumn title]];
                }
                if ([dataColumn theDescription]) {
                    [info appendFormat:@"\n\tThe Description: %@", [dataColumn theDescription]];
                }
                if ([dataColumn mimeType]) {
                    [info appendFormat:@"\n\tMime Type: %@", [dataColumn mimeType]];
                }
            }

        }
    }
    @catch (NSException *e) {
        [info appendString:[e description]];
    }
    @finally {
        [geoPackage close];
    }
    return info;
}


-(NSString *) getTitleAndSubtitleWithMapPoint: (GPKGMapPoint *) mapPoint andDelimiter: (NSString *) delimiter{
    NSMutableString * value = [[NSMutableString alloc] init];
    [value appendString:mapPoint.title];
    if(mapPoint.subtitle != nil){
        if(delimiter != nil){
            [value appendString:delimiter];
        }
        [value appendString:mapPoint.subtitle];
    }
    return value;
}

-(NSString *) buildInfoForExistingFeatureMapPoint: (GPKGMapPoint *) mapPoint{
    
    NSMutableString * info = [[NSMutableString alloc] init];
    
    GPKGSMapPointData * data = [self getOrCreateDataWithMapPoint:mapPoint];
    
    self.manager = [GPKGGeoPackageFactory manager];
    
    GPKGGeoPackage * geoPackage = [self.manager open:data.database];
    @try {
        
        GPKGFeatureDao * featureDao = [geoPackage featureDaoWithTableName:data.tableName];
        
        GPKGDataColumnsDao * dataColumnsDao = [[[GPKGSchemaExtension alloc] init] dataColumnsDao];
        
        NSNumber * featureId = [NSNumber numberWithInt:data.featureId];
        if(featureId != nil){
            GPKGFeatureRow * featureRow = (GPKGFeatureRow *)[featureDao queryForIdObject:featureId];
            
            if(featureRow != nil){
                
                int geometryColumn = [featureRow geometryColumnIndex];
                for(int i = 0; i < featureRow.columnCount; i++){
                    if(i != geometryColumn){
                        NSObject * value = [featureRow valueWithIndex:i];
                        if(value != nil){
                            GPKGDataColumns * dataColumn = [dataColumnsDao dataColumnByTableName:data.tableName andColumnName:[featureRow columnWithIndex:i].name];
                            NSString *columnName = [featureRow columnWithIndex:i].name;
                            if (dataColumn) {
                                columnName = dataColumn.name;
                            }
                            [info appendFormat:@"%@: %@\n", columnName, value];
                        }
                    }
                }
                
                GPKGGeometryData * geomData = [featureRow geometry];
                if(geomData != nil){
                    SFGeometry * geometry = geomData.geometry;
                    if(geometry != nil){
                        
                        if(info.length > 0){
                            [info appendString:@"\n"];
                        }
                        
                        [info appendString:[SFGeometryPrinter geometryString:geometry]];
                    }
                }
            }
        }
        
    }
    @catch (NSException *e) {
        [GPKGSUtils showMessageWithDelegate:self
                                   andTitle:[GPKGSProperties getValueOfProperty:GPKGS_PROP_EDIT_FEATURES_DELETE_LABEL]
                                 andMessage:[NSString stringWithFormat:@"%@", [e description]]];
    }
    @finally {
        [geoPackage close];
    }
    
    return info;
}

-(NSString *) buildInfoForGenericMapPoint: (GPKGMapPoint *) mapPoint{
    NSMutableString * info = [[NSMutableString alloc] init];
    [info appendFormat:@"Latitude: %f", mapPoint.coordinate.latitude];
    [info appendFormat:@"\nLongitude: %f", mapPoint.coordinate.longitude];
    return info;
}



- (IBAction)backButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
