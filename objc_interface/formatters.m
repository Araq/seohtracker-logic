#import "formatters.h"

#import "ELHASO.h"

#import <assert.h>


static NSDateFormatter *relative_normal_formatter_;
static NSDateFormatter *relative_shadow_formatter_;
static dispatch_queue_t q;


/** Initializes the formatters along with the queue to access them.
 *
 * Call as much as you want, it will only do the job once.
 */
static void init_formatters(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
            q = dispatch_queue_create("formatters.m", DISPATCH_QUEUE_SERIAL);
            assert(q);

            // Normal relative dates.
            relative_normal_formatter_ = [NSDateFormatter new];
            [relative_normal_formatter_
                setTimeStyle:NSDateFormatterMediumStyle];
            [relative_normal_formatter_
                setDateStyle:NSDateFormatterMediumStyle];
            relative_normal_formatter_.doesRelativeDateFormatting = YES;
            assert(relative_normal_formatter_);

            // Used for the part of the time we want to not shadow.
            relative_shadow_formatter_ = [NSDateFormatter new];
            [relative_shadow_formatter_
                setTimeStyle:NSDateFormatterMediumStyle];
            [relative_shadow_formatter_
                setDateStyle:NSDateFormatterNoStyle];
            relative_shadow_formatter_.doesRelativeDateFormatting = YES;

        });
}

/** Wraps format_relative_nsdate with a TWeight* accessor.
 *
 * Returns the empty string if something went wrong.
 */
NSString *format_relative_date(TWeight *weight)
{
    if (!weight) return @"";
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:date(weight)];
    return format_relative_nsdate(d);
}

/** Formats a date to text format using relative date formatting.
 *
 * Returns the empty string if something went wrong.
 */
NSString *format_relative_nsdate(NSDate *date)
{
    init_formatters();
    if (!date) return @"";
    NSString __block *ret = nil;
    dispatch_sync(q, ^{
            ret = [relative_normal_formatter_ stringFromDate:date];
        });

    assert(ret);
    return ret;
}

/** Like format_relative_nsdate but shadows the part of the date day.
 *
 * This is used for the cases where a same day entry is displayed. The second
 * (and further) entries of the same day are displayed in a shadowed color.
 */
NSAttributedString *format_shadowed_date(TWeight *weight,
    id font, id normal_color, id shadowed_color)
{
    init_formatters();
    assert(weight && @"Bad param");
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:date(weight)];

    // First create the attribute string with the normal text.
    NSString *normal_text = format_relative_nsdate(d);
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc]
        initWithString:normal_text attributes:@{NSFontAttributeName:font}];

    // Find the range of the text we will keep in normal color.
    NSString __block *part = nil;
    dispatch_sync(q, ^{
            part = [relative_shadow_formatter_ stringFromDate:d];
        });
    assert(part);
    const NSRange r = [normal_text
        rangeOfString:part options:NSCaseInsensitiveSearch];
    if (NSNotFound == r.location) {
        DLOG(@"Weird, could not find '%@' in original date string?", part);
        return text;
    }

    // By default make all the text shadowed.
    [text addAttribute:NSForegroundColorAttributeName
        value:shadowed_color range:(NSRange){0, text.length}];
    // Then modify the part we want to be seen.
    [text addAttribute:NSForegroundColorAttributeName
        value:normal_color range:r];
    return text;
}

/** Call this when the time changes significantly.
 *
 * This could be when the user changes date, or the current time naturally
 * switches from one day to another. The function will refresh the internal
 * time variables used to keep track of specific date limits used for
 * formatting.
 */
void update_formatters_on_significant_time_change(void)
{
}
