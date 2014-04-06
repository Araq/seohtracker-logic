#import "n_global.h"

NSString *format_relative_date(TWeight *weight);
NSString *format_relative_nsdate(NSDate *date);

NSAttributedString *format_shadowed_date(TWeight *weight,
    id font, id normal_color, id shadowed_color);

void update_formatter_limits_on_significant_time_change(void);
