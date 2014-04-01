#import "n_global.h"

@interface SHNotifications : NSObject

+ (void)post_decimal_separator_changed;
+ (void)post_did_accept_file:(NSString*)file;

@end

extern NSString *decimal_separator_changed;
extern NSString *did_accept_file;
extern NSString *did_accept_file_path;
extern NSString *did_add_row;
extern NSString *did_add_row_pos;
extern NSString *did_change_changelog_version;
extern NSString *did_import_csv;
extern NSString *did_remove_row;
extern NSString *did_select_sync_tab;
extern NSString *did_update_last_row;
extern NSString *user_metric_prefereces_changed;
