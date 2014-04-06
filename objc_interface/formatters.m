#import "formatters.h"

#import "ELHASO.h"

#import <assert.h>


#define NUM_FORMATTERS_ 4

// Array of year date, month date, near date, and relative date.
static NSDateFormatter *normal_formatter_[NUM_FORMATTERS_];
static NSDateFormatter *shadow_formatter_[NUM_FORMATTERS_];
static NSDateFormatter *relative_formatter_;
static dispatch_queue_t q;
// Stores the limit to differentiate the date format.
static NSDate *year_limit_, *month_limit_;


/// Rebuilds the global date formatters.
static void generate_formatters(void)
{
    NSDateFormatter *f = nil;

    // Normal year long relative dates.
    f = [NSDateFormatter new];
    [f setTimeStyle:NSDateFormatterMediumStyle];
    [f setDateStyle:NSDateFormatterMediumStyle];
    f.doesRelativeDateFormatting = NO;
    assert(f);
    normal_formatter_[0] = f;

    // Shadow year long relative dates.
    f = [NSDateFormatter new];
    [f setTimeStyle:NSDateFormatterMediumStyle];
    [f setDateStyle:NSDateFormatterNoStyle];
    f.doesRelativeDateFormatting = NO;
    assert(f);
    shadow_formatter_[0] = f;

#define _F(X) [NSDateFormatter \
dateFormatFromTemplate:X options:0 \
locale:[NSLocale autoupdatingCurrentLocale]]

    // Figure out a locale date format without year.
    f = [NSDateFormatter new];
    [f setDateFormat:_F(@"eeeMMMd,jjmmssa")];
    f.doesRelativeDateFormatting = NO;
    assert(f);
    normal_formatter_[1] = f;

    f = [NSDateFormatter new];
    [f setDateFormat:_F(@"jjmmssa")];
    f.doesRelativeDateFormatting = NO;
    assert(f);
    shadow_formatter_[1] = f;

    // Figure out a locale date format without year or month, only day.
    f = [NSDateFormatter new];
    [f setDateFormat:_F(@"eeeed,jjmmssa")];
    f.doesRelativeDateFormatting = NO;
    assert(f);
    normal_formatter_[2] = f;

    f = [NSDateFormatter new];
    [f setDateFormat:_F(@"jjmmssa")];
    f.doesRelativeDateFormatting = NO;
    assert(f);
    shadow_formatter_[2] = f;

    // The last entries are like the zeroth ones but use words.
    f = [NSDateFormatter new];
    [f setTimeStyle:NSDateFormatterMediumStyle];
    [f setDateStyle:NSDateFormatterMediumStyle];
    f.doesRelativeDateFormatting = YES;
    assert(f);
    normal_formatter_[3] = f;

    f = [NSDateFormatter new];
    [f setTimeStyle:NSDateFormatterMediumStyle];
    [f setDateStyle:NSDateFormatterNoStyle];
    f.doesRelativeDateFormatting = YES;
    assert(f);
    shadow_formatter_[3] = f;
#undef _F

    // Debug format sets for the dates.
    for (int i = 0; i < NUM_FORMATTERS_; i++) {
        f = normal_formatter_[i];
        DLOG(@"Format date %d is '%@'", i, [f dateFormat]);
    }
}

/** Initializes the formatters along with the queue to access them.
 *
 * Call as much as you want, it will only do the job once.
 */
static void init_formatters(void)
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
            // Creates the internal queue.
            q = dispatch_queue_create("formatters.m", DISPATCH_QUEUE_SERIAL);
            assert(q);

            // Updates stuff.
            update_formatter_limits_on_significant_time_change();
        });
}

/// Returns the appropriate formatter index for `date`.
static int select_formatter_index(NSDate *date)
{
    if ([date laterDate:year_limit_] == year_limit_)
        return 0;
    if ([date laterDate:month_limit_] == month_limit_)
        return 1;

    // At this point we have to make a format text to choose 2 or 3.
    __block BOOL is_relative = NO;
    dispatch_sync(q, ^{
            NSString *d1 = [normal_formatter_[0] stringFromDate:date];
            NSString *d2 = [normal_formatter_[NUM_FORMATTERS_ - 1]
                stringFromDate:date];
            if (![d1 isEqualToString:d2])
                is_relative = YES;
        });
    return (is_relative ? 3 : 2);
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
    const int formatter_index = select_formatter_index(date);
    NSString __block *ret = nil;
    dispatch_sync(q, ^{
            ret = [normal_formatter_[formatter_index] stringFromDate:date];
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
    const int formatter_index = select_formatter_index(d);

    // First create the attribute string with the normal text.
    NSString *normal_text = format_relative_nsdate(d);
    NSMutableAttributedString *text = [[NSMutableAttributedString alloc]
        initWithString:normal_text attributes:@{NSFontAttributeName:font}];

    // Find the range of the text we will keep in normal color.
    NSString __block *part = nil;
    dispatch_sync(q, ^{
            part = [shadow_formatter_[formatter_index] stringFromDate:d];
        });
    assert(part);
    const NSRange r = [normal_text
        rangeOfString:part options:NSCaseInsensitiveSearch];
    if (NSNotFound == r.location) {
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

/** Call this when locale or time changes significantly.
 *
 * Using the current time as bases figures out what time limits have to be used
 * for dates earlier than the current year, dates earlier than the current
 * month, and nearest dates.
 *
 * Since this is based on the current time, you have to call this whenever the
 * date changes from day to day (or more). The function will update the
 * internal limits used to figure out which date formatter to pick.
 *
 * The locale affects the formatting too, so it should also be treated.
 */
void update_formatter_limits_on_significant_time_change(void)
{
    if (!q)
        return;

    dispatch_sync(q, ^{
            NSCalendar *cal = [NSCalendar autoupdatingCurrentCalendar];
            const unsigned unit_flags = NSYearCalendarUnit |
                NSMonthCalendarUnit | NSDayCalendarUnit |
                NSHourCalendarUnit | NSMinuteCalendarUnit |
                NSSecondCalendarUnit;
            NSDateComponents *comps = [cal components:unit_flags
                fromDate:[NSDate date]];

            [comps setHour:1];
            [comps setMinute:0];
            [comps setSecond:1];
            [comps setDay:1];
            month_limit_ = [cal dateFromComponents:comps];
            [comps setMonth:1];
            year_limit_ = [cal dateFromComponents:comps];
            DLOG(@"Formatter month limit %@, year limit %@",
                month_limit_, year_limit_);

            generate_formatters();
        });
}
