#import "formatters.h"

#import "ELHASO.h"

/** Wraps format_nsdate with a TWeight* accessor.
 *
 * Returns the empty string if something went wrong.
 */
NSString *format_date(TWeight *weight)
{
    if (!weight) return @"";
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:date(weight)];
    return format_nsdate(d);
}

/** Formats a date to text format.
 *
 * Returns the empty string if something went wrong.
 */
NSString *format_nsdate(NSDate *date)
{
    if (!date) return @"";

    static NSDateFormatter *formatter = nil;
    if (!formatter) {
        formatter = [NSDateFormatter new];
        [formatter setTimeStyle:NSDateFormatterMediumStyle];
        [formatter setDateStyle:NSDateFormatterMediumStyle];
    }
    if (!formatter) return @"";
    return [formatter stringFromDate:date];
}
