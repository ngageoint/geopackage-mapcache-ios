//
//  GPKGSLinkedTablesViewController.m
//  mapcache-ios
//
//  Created by Brian Osborn on 2/8/16.
//  Copyright © 2016 NGA. All rights reserved.
//

#import "GPKGSLinkedTablesViewController.h"
#import "GPKGSTableCell.h"
#import "GPKGFeatureTileTableLinker.h"
#import "GPKGSConstants.h"

@interface GPKGSLinkedTablesViewController ()

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *tableCells;
@property (nonatomic, strong) NSMutableSet * linkedTableSet;

@end

@implementation GPKGSLinkedTablesViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Get a feature tile table linker
    GPKGGeoPackage * geoPackage = [self.manager open:self.table.database];
    GPKGFeatureTileTableLinker * linker = [[GPKGFeatureTileTableLinker alloc] initWithGeoPackage:geoPackage];
    
    // Get the tables that can be linked and the currently linked tables
    NSArray * tables = nil;
    GPKGResultSet * linkedTableResults = nil;
    switch([self.table getType]){
        case GPKGS_TT_FEATURE:
            tables = [geoPackage tileTables];
            linkedTableResults = [linker queryForFeatureTable:self.table.name];
            break;
        case GPKGS_TT_TILE:
            tables = [geoPackage featureTables];
            linkedTableResults = [linker queryForTileTable:self.table.name];
            break;
        default:
            [NSException raise:@"Unexpected Type" format:@"Unexpected table type: %u", [self.table getType]];
    }
    
    // Build a set of currently linked tables
    self.linkedTableSet = [[NSMutableSet alloc] init];
    while([linkedTableResults moveToNext]){
        GPKGFeatureTileLink * link = [linker linkFromResultSet:linkedTableResults];
        switch([self.table getType]){
            case GPKGS_TT_FEATURE:
                [self.linkedTableSet addObject:link.tileTableName];
                break;
            case GPKGS_TT_TILE:
                [self.linkedTableSet addObject:link.featureTableName];
                break;
            default:
                break;
        }
    }
    [linkedTableResults close];
    
    self.tableCells = [[NSMutableArray alloc] init];
    for(NSString * table in tables){
        GPKGSTable * linkTable = [[GPKGSTable alloc] initWithDatabase:self.table.database andName:table andCount:0];
        linkTable.active = [self.linkedTableSet containsObject:table];
        [self.tableCells addObject:linkTable];
    }
    
    // Close the GeoPackage
    [geoPackage close];
}

- (void) viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    [self.tableView reloadData];
}

- (IBAction)cancelButton:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)editButton:(id)sender {
    
    // Determine which links were newly checked or removed
    NSMutableArray * newLinks = [[NSMutableArray alloc] init];
    NSMutableArray * removedLinks = [[NSMutableArray alloc] init];
    for(GPKGSTable * linkTable in self.tableCells){
        BOOL wasActive = [self.linkedTableSet containsObject:linkTable.name];
        if(linkTable.active){
            if(!wasActive){
                [newLinks addObject:linkTable.name];
            }
        } else if(wasActive){
            [removedLinks addObject:linkTable.name];
        }
    }
    
    // Check if we need to unlink or link tables
    BOOL edited = removedLinks.count > 0 || newLinks.count > 0;
    if(edited){
        
        // Create a linker
        GPKGGeoPackage * geoPackage = [self.manager open:self.table.database];
        GPKGFeatureTileTableLinker * linker = [[GPKGFeatureTileTableLinker alloc] initWithGeoPackage:geoPackage];
        
        // Delete links
        for(NSString * removedLink in removedLinks){
            switch([self.table getType]){
                case GPKGS_TT_FEATURE:
                    [linker deleteLinkWithFeatureTable:self.table.name andTileTable:removedLink];
                    break;
                case GPKGS_TT_TILE:
                    [linker deleteLinkWithFeatureTable:removedLink andTileTable:self.table.name];
                    break;
                default:
                    break;
            }
        }
        
        // Create links
        for(NSString * newLink in newLinks){
            switch([self.table getType]){
                case GPKGS_TT_FEATURE:
                    [linker linkWithFeatureTable:self.table.name andTileTable:newLink];
                    break;
                case GPKGS_TT_TILE:
                    [linker linkWithFeatureTable:newLink andTileTable:self.table.name];
                    break;
                default:
                    break;
            }
        }
        
        // Close the GeoPackage and mark as changes made
        [geoPackage close];
    }
    
    [self.delegate linkedTablesViewController:self linksEdited:edited withError:nil];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.tableCells count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    GPKGSTable * linkTable = (GPKGSTable *) [self.tableCells objectAtIndex:indexPath.row];
    GPKGSTableCell * tableCell = (GPKGSTableCell *) [tableView dequeueReusableCellWithIdentifier:GPKGS_CELL_LINKED_TABLE forIndexPath:indexPath];
    tableCell.active.on = linkTable.active;
    [tableCell.tableName setText:linkTable.name];
    [tableCell.active setTable:linkTable];
    tableCell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return tableCell;
}

- (IBAction)tableActiveChanged:(GPKGSActiveTableSwitch *)sender {
    GPKGSTable * table = sender.table;
    table.active = sender.on;
}

@end
