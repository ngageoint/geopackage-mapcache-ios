//
//  GPKGSDatabases.m
//  geopackage-sample-ios
//
//  Created by Brian Osborn on 7/10/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSDatabases.h"

static GPKGSDatabases * instance;

@interface GPKGSDatabases ()

@property (nonatomic, strong) NSUserDefaults * settings;
@property (nonatomic, strong) NSMutableDictionary * databases;

@end

@implementation GPKGSDatabases

+(GPKGSDatabases *) getInstance{
    if(instance == nil){
        NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
        GPKGSDatabases * active = [[GPKGSDatabases alloc] initWithSettings:settings];
        [active loadFromPreferences];
        instance = active;
    }
    return instance;
}

-(instancetype) initWithSettings: (NSUserDefaults *) settings{
    self = [super init];
    if(self != nil){
        self.settings = settings;
        self.modified = false;
        self.databases = [[NSMutableDictionary alloc] init];
    }
    return self;
}

-(BOOL) exists: (GPKGSTable *) table{
    BOOL exists = false;
    GPKGSDatabase * database = [self getDatabaseWithTable:table];
    if(database != nil) {
        exists = [database exists:table];
    }
    return exists;
}

-(NSArray *) featureOverlays: (NSString *) database{
    return [[NSArray alloc] init]; //TODO
}

-(GPKGSDatabase *) getDatabaseWithTable:(GPKGSTable *) table{
    return [self getDatabaseWithName:table.database];
}

-(GPKGSDatabase *) getDatabaseWithName:(NSString *) database{
    return [self.databases objectForKey:database];
}

-(NSArray *) getDatabases{
    return [self.databases allValues];
}

-(void) addTable: (GPKGSTable *) table{
    [self addTable:table andUpdatePreferences:true];
}

-(void) addTable: (GPKGSTable *) table andUpdatePreferences: (BOOL) updatePreferences{
    GPKGSDatabase * database = [self.databases objectForKey:table.database];
    if(database == nil){
        database = [[GPKGSDatabase alloc] initWithName:table.database andExpanded:false];
        [self.databases setObject:database forKey:table.database];
    }
    [database add:table];
    if(updatePreferences){
        [self addTableToPreferences: table];
    }
    self.modified = true;
}

-(void) removeTable: (GPKGSTable *) table{
    GPKGSDatabase * database = [self.databases objectForKey:table.database];
    if(database != nil){
        [database remove:table];
        [self removeTableFromPreferences:table];
        if([database isEmpty]){
            [self.databases removeObjectForKey:database.name];
            [self removeDatabaseFromPreferences:database.name andPreserveOverlays:false];
        }
        self.modified = true;
    }
}

-(BOOL) isEmpty{
    return [self count] == 0;
}

-(int) count{
    int count = 0;
    for(GPKGSTable * database in [self.databases allValues]){
        GPKGSDatabase * db = [self.databases objectForKey:database.name];
        count += [db getTableCount];
    }
    return count;
}

-(void) clearActive{
    NSMutableArray * allDatabases = [[NSMutableArray alloc] init];
    [allDatabases addObjectsFromArray:[self.databases allKeys]];
    for(NSString * database in allDatabases){
        GPKGSDatabase * db = [self.databases objectForKey:database];
        for(GPKGSTable * table in [db getFeatureOverlays]){
            if(table.active){
                table.active = false;
                [self addTable:table andUpdatePreferences:true];
            }
        }
        [self removeDatabase:database andPreserveOverlays:true];
    }
}

-(void) removeDatabase: (NSString *) database andPreserveOverlays: (BOOL) preserveOverlays{
    [self.databases removeObjectForKey:database];
    [self removeDatabaseFromPreferences:database andPreserveOverlays:preserveOverlays];
    self.modified = true;
}

-(void) renameDatabase: (NSString *) database asNewDatabase: (NSString *) newDatabase{
    GPKGSDatabase * geoPackageDatabase = [self.databases objectForKey:database];
    if(geoPackageDatabase != nil){
        [self.databases removeObjectForKey:database];
        geoPackageDatabase.name = newDatabase;
        [self.databases setObject:geoPackageDatabase forKey:newDatabase];
        [self removeDatabaseFromPreferences:database andPreserveOverlays:false];
        for(GPKGSTable * table in [geoPackageDatabase getTables]){
            table.database = newDatabase;
            [self addTableToPreferences:table];
        }
    }
    self.modified = true;
}

-(void) loadFromPreferences{
    // TODO
}

-(void) removeDatabaseFromPreferences: (NSString *) database andPreserveOverlays: (BOOL) preserveOverlays{
    // TODO
}

-(void) removeTableFromPreferences: (GPKGSTable *) table{
    // TODO
}

-(void) addTableToPreferences: (GPKGSTable *) table{
    // TODO
}

@end
