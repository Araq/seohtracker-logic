#import "SHNotifications.h"

#import "ELHASO.h"


NSString *decimal_separator_changed = @"decimal_separator_changed";
NSString *did_accept_file = @"NSNotificationDidAcceptFile";
NSString *did_accept_file_path = @"NSNotificationDidAcceptFilePath";
NSString *did_add_row = @"NSNotificationDidAddRow";
NSString *did_add_row_pos = @"NSNotificationDidAddRowPos";
NSString *did_change_changelog_version = @"NSNotificationDidChangeLogVersion";
NSString *did_import_csv = @"NSNotificationDidImportCSV";
NSString *did_remove_row = @"NSNotificationDidRemoveRow";
NSString *did_select_sync_tab = @"NSNotificationDidSelectSyncTab";
NSString *did_update_last_row = @"NSNotificationDidUpdateLastRow";
NSString *user_metric_prefereces_changed = @"user_metric_preferences_changed";

//##define BUILD_POST(name)

+ (void)post_decimal_separator_changed
{
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:decimal_separator_changed object:nil];
}

+ (void)post_did_accept_file:(NSString*)file
{
    LASSERT(file.length, @"No file value?");
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center postNotificationName:did_accept_file object:nil
        userInfo:@{did_accept_file_path:target}];
}
