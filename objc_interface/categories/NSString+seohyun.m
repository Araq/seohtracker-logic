#import "NSString+seohyun.h"

#import "ELHASO.h"
#import "n_global.h"

@implementation NSString (seohyun)

/** Parses the current text as a float using the locale decimal separator.
 *
 * Avoids returning NANs by returning zero instead.
 */
- (float)locale_float
{
    const double value = [[NSDecimalNumber
        decimalNumberWithString:self locale:[NSLocale currentLocale]]
            doubleValue];
    if (isnan(value))
        return 0;
    else
        return value;
}

- (BOOL)is_valid_weight
{
    return (true == is_weight_input_valid((char*)[self UTF8String]));
}

/// Returns the UTF8String wrapped with a cast to avoid annoying warnings.
- (char*)cstring
{
    return (char*)[self UTF8String];
}

@end
