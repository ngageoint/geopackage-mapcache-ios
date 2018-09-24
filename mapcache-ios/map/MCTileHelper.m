//
//  MCTileHelper.m
//  mapcache-ios
//
//  Created by Tyler Burgett on 9/20/18.
//  Copyright © 2018 NGA. All rights reserved.
//

#import "MCTileHelper.h"


@interface MCTileHelper()
@property (nonatomic, strong) GPKGGeoPackageManager *manager;
@property (nonatomic, strong) GPKGBoundingBox * tilesBoundingBox;
@end


@implementation MCTileHelper

//-(void) displayTiles: (GPKGSTileTable *)
-(MKTileOverlay *) createOverlayForTiles: (GPKGSTileTable *) tiles fromGeoPacakge:(GPKGGeoPackage *) geoPackage {
    GPKGTileDao * tileDao = [geoPackage getTileDaoWithTableName:tiles.name];
    GPKGTileTableScaling *tileTableScaling = [[GPKGTileTableScaling alloc] initWithGeoPackage:geoPackage andTileDao:tileDao];
    GPKGTileScaling *tileScaling = [tileTableScaling get];
    GPKGBoundedOverlay * overlay = [GPKGOverlayFactory boundedOverlay:tileDao andScaling:tileScaling];
    overlay.canReplaceMapContent = false;
    
    GPKGTileMatrixSet * tileMatrixSet = tileDao.tileMatrixSet;
    
    //    GPKGFeatureTileTableLinker * linker = [[GPKGFeatureTileTableLinker alloc] initWithGeoPackage:geoPackage];
    //    NSArray<GPKGFeatureDao *> * featureDaos = [linker getFeatureDaosForTileTable:tileDao.tableName];
    //    for(GPKGFeatureDao * featureDao in featureDaos){
    //
    //        // Create the feature tiles
    //        GPKGFeatureTiles * featureTiles = [[GPKGFeatureTiles alloc] initWithFeatureDao:featureDao];
    //
    //        // Create an index manager
    //        GPKGFeatureIndexManager * indexer = [[GPKGFeatureIndexManager alloc] initWithGeoPackage:geoPackage andFeatureDao:featureDao];
    //        [featureTiles setIndexManager:indexer];
    //
    //        self.featureOverlayTiles = true;
    //
    //        // Add the feature overlay query
    ////        GPKGFeatureOverlayQuery * featureOverlayQuery = [[GPKGFeatureOverlayQuery alloc] initWithBoundedOverlay:overlay andFeatureTiles:featureTiles];
    //        [self.featureOverlayQueries addObject:featureOverlayQuery];
    //    }
    
    GPKGBoundingBox *displayBoundingBox = [tileMatrixSet getBoundingBox];
    GPKGTileMatrixSetDao * tileMatrixSetDao = [geoPackage getTileMatrixSetDao];
    GPKGSpatialReferenceSystem *tileMatrixSetSrs = [tileMatrixSetDao getSrs:tileMatrixSet];
    GPKGContents *contents = [tileMatrixSetDao getContents:tileMatrixSet];
    GPKGBoundingBox *contentsBoundingBox = [contents getBoundingBox];
    if(contentsBoundingBox != nil){
        GPKGContentsDao *contentsDao = [geoPackage getContentsDao];
        SFPProjectionTransform *transform = [[SFPProjectionTransform alloc] initWithFromProjection:[[contentsDao getSrs:contents] projection] andToProjection:[tileMatrixSetSrs projection]];
        GPKGBoundingBox *transformedContentsBoundingBox = contentsBoundingBox;
        if(![transform isSameProjection]){
            transformedContentsBoundingBox = [transformedContentsBoundingBox transform:transform];
        }
        displayBoundingBox = [GPKGTileBoundingBoxUtils overlapWithBoundingBox:displayBoundingBox andBoundingBox:transformedContentsBoundingBox];
    }
    
//    [self displayTilesWithOverlay:overlay andBoundingBox:displayBoundingBox andSrs:tileMatrixSetSrs andSpecifiedBoundingBox:nil];
    
    return [self getTileOverlayWith:overlay andBoundingBox:displayBoundingBox andSrs:tileMatrixSetSrs andSpecifiedBoundingBox:nil];
}


//-(void) displayTilesWithOverlay: (MKTileOverlay *) overlay andBoundingBox: (GPKGBoundingBox *) dataBoundingBox andSrs: (GPKGSpatialReferenceSystem *) srs andSpecifiedBoundingBox: (GPKGBoundingBox *) specifiedBoundingBox{
-(MKTileOverlay* ) getTileOverlayWith: (MKTileOverlay *) overlay andBoundingBox: (GPKGBoundingBox *) dataBoundingBox andSrs: (GPKGSpatialReferenceSystem *) srs andSpecifiedBoundingBox: (GPKGBoundingBox *) specifiedBoundingBox{

    GPKGBoundingBox * boundingBox = dataBoundingBox;
    if(boundingBox != nil){
        boundingBox = [self transformBoundingBoxToWgs84:boundingBox withSrs:srs];
    }else{
        boundingBox = [[GPKGBoundingBox alloc] initWithMinLongitudeDouble:-PROJ_WGS84_HALF_WORLD_LON_WIDTH andMinLatitudeDouble:PROJ_WEB_MERCATOR_MIN_LAT_RANGE andMaxLongitudeDouble:PROJ_WGS84_HALF_WORLD_LON_WIDTH andMaxLatitudeDouble:PROJ_WEB_MERCATOR_MAX_LAT_RANGE];
    }
    
    if(specifiedBoundingBox != nil){
        boundingBox = [GPKGTileBoundingBoxUtils overlapWithBoundingBox:boundingBox andBoundingBox:specifiedBoundingBox];
    }
    
    if(self.tilesBoundingBox == nil){
        self.tilesBoundingBox = boundingBox;
    }else{
        self.tilesBoundingBox = [GPKGTileBoundingBoxUtils unionWithBoundingBox:self.tilesBoundingBox andBoundingBox:boundingBox];
    }
    
    // TODO replace with a return and have the map view
//    dispatch_sync(dispatch_get_main_queue(), ^{
//        [self.mapView addOverlay:overlay];
//    });
    
    return overlay;
}


-(GPKGBoundingBox *) transformBoundingBoxToWgs84: (GPKGBoundingBox *) boundingBox withSrs: (GPKGSpatialReferenceSystem *) srs{
    
    SFPProjection *projection = [srs projection];
    if([projection getUnit] == SFP_UNIT_DEGREES){
        boundingBox = [GPKGTileBoundingBoxUtils boundDegreesBoundingBoxWithWebMercatorLimits:boundingBox];
    }
    SFPProjectionTransform *transformToWebMercator = [[SFPProjectionTransform alloc] initWithFromProjection:projection andToEpsg:PROJ_EPSG_WEB_MERCATOR];
    GPKGBoundingBox *webMercatorBoundingBox = [boundingBox transform:transformToWebMercator];
    SFPProjectionTransform *transform = [[SFPProjectionTransform alloc] initWithFromEpsg:PROJ_EPSG_WEB_MERCATOR andToEpsg:PROJ_EPSG_WORLD_GEODETIC_SYSTEM];
    boundingBox = [webMercatorBoundingBox transform:transform];
    return boundingBox;
}

@end
