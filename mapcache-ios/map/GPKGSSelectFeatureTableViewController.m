//
//  GPKGSSelectFeatureTableViewController.m
//  mapcache-ios
//
//  Created by Brian Osborn on 8/11/15.
//  Copyright (c) 2015 NGA. All rights reserved.
//

#import "GPKGSSelectFeatureTableViewController.h"
#import "GPKGSUtils.h"

@interface GPKGSSelectFeatureTableViewController ()

@property (nonatomic, strong) NSArray * databases;
@property (nonatomic, strong) NSArray * tables;
@property (nonatomic, strong) NSDictionary * tableMapping;
@property (nonatomic) int defaultDatabase;
@property (nonatomic) int defaultTable;

@end

@implementation GPKGSSelectFeatureTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.defaultDatabase = 0;
    self.defaultTable = 0;
    BOOL searchForActive = true;
    
    NSMutableArray * tempDatabases = [[NSMutableArray alloc] init];
    NSMutableDictionary * tempTableMapping = [[NSMutableDictionary alloc] init];
    NSArray * allDatabases = [self.manager databases];
    for(NSString * database in allDatabases){
        NSArray * featureTables = [self getFeatureTables:database];
        if([featureTables count] > 0){
            int databaseIndex = (int)[tempDatabases count];
            [tempTableMapping setObject:featureTables forKey:[NSNumber numberWithInt:databaseIndex]];
            [tempDatabases addObject:database];
            if(searchForActive){
                for(int tableIndex = 0; tableIndex < [featureTables count]; tableIndex++){
                    NSString * featureTable = [featureTables objectAtIndex:tableIndex];
                    BOOL active = [self.active existsWithDatabase:database andTable:featureTable ofType:GPKGS_TT_FEATURE];
                    if(active){
                        self.defaultDatabase = databaseIndex;
                        self.defaultTable = tableIndex;
                        searchForActive = false;
                        break;
                    }
                }
            }
        }
    }
    self.databases = tempDatabases;
    self.tableMapping = tempTableMapping;
    
    if([self.databases count] == 0){
        [GPKGSUtils disableButton:self.okButton];
    }else{
        self.tables = [self.tableMapping objectForKey:[NSNumber numberWithInt:0]];
        self.databasePicker.dataSource = self;
        self.databasePicker.delegate = self;
        self.featurePicker.dataSource = self;
        self.featurePicker.delegate = self;
    }
}

- (void)viewDidAppear:(BOOL)animated{
    if(self.defaultDatabase > 0){
        [self.databasePicker selectRow:self.defaultDatabase inComponent:0 animated:YES];
        [self.databasePicker reloadComponent:0];
        self.tables = [self.tableMapping objectForKey:[NSNumber numberWithInt:self.defaultDatabase]];
    }
    if(self.defaultDatabase > 0 || self.defaultTable > 0){
        [self.featurePicker selectRow:self.defaultTable inComponent:0 animated:YES];
        [self.featurePicker reloadComponent:0];
    }
}

- (IBAction)cancel:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)selectButton:(id)sender {
    if(self.delegate != nil){
        NSInteger databaseRow = [self.databasePicker selectedRowInComponent:0];
        NSString * database = [self.databases objectAtIndex:databaseRow];
        NSInteger tableRow = [self.featurePicker selectedRowInComponent:0];
        NSString * table = [self.tables objectAtIndex:tableRow];
        [self.delegate selectFeatureTableViewController:self database:database table:table request:self.request];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    if (pickerView.tag == 1){
        return self.databases.count;
    }else{
        return self.tables.count;
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    if (pickerView.tag == 1){
        return [self.databases objectAtIndex:row];
    }else{
        return [self.tables objectAtIndex:row];
    }
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    if (pickerView.tag == 1){
        self.tables = [self.tableMapping objectForKey:[NSNumber numberWithInteger:row]];
        [self.featurePicker reloadAllComponents];
    }
}

- (NSArray *) getFeatureTables: (NSString *) database{
    NSArray * tables = nil;
    GPKGGeoPackage * geopackage = [self.manager open:database];
    @try {
        tables = [geopackage getFeatureTables];
    }
    @finally {
        [geopackage close];
    }
    return tables;
}

@end
