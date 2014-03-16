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

/** Formats a date to text format using relative date formatting.
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
        formatter.doesRelativeDateFormatting = YES;
    }
    if (!formatter) return @"";
    return [formatter stringFromDate:date];
}

/** Like format_nsdate but shadows the part of the date day.
 *
 * This is used for the cases where a same day entry is displayed. The second
 * (and further) entries of the same day are displayed in a shadowed color.
 */
NSAttributedString *format_shadowed_date(TWeight *weight,
    UIFont *font, UIColor *normal, UIColor *shadowed)
{
    assert(weight && @"Bad param");
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:date(weight)];

    // First create the attribute string with the normal text.
    NSString *normal_text = format_nsdate(d);
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc]
        initWithString:normal_text attributes:@{NSFontAttributeName:font}];

    // Now find the range for the time part we want to NOT shadow.
    static NSDateFormatter *formatter = nil;
    if (!formatter) {
        formatter = [NSDateFormatter new];
        [formatter setTimeStyle:NSDateFormatterMediumStyle];
        [formatter setDateStyle:NSDateFormatterNoStyle];
        formatter.doesRelativeDateFormatting = YES;
    }

    // Find the range of the text we will keep in normal color.
    NSString *part = [formatter stringFromDate:d];
    const NSRange r = [normal_text
        rangeOfString:part options:NSCaseInsensitiveSearch];
    if (NSNotFound == r.location) {
        DLOG(@"Weird, could not find '%@' in original date string?", part);
        return text;
    }

    // By default make all the text shadowed.
    [text addAttribute:NSForegroundColorAttributeName
        value:shadowed range:(NSRange){0, text.length}];
    // Then modify the part we want to be seen.
    [text addAttribute:NSForegroundColorAttributeName
        value:normal range:r];
    return text;
}
