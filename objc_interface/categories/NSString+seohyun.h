#import <Foundation/Foundation.h>

/** \class NSString
 * Appends some custom helpers to NSString for easier Nimrod interfacing.
 */
@interface NSString (seohyun)

- (float)locale_float;
- (BOOL)is_valid_weight;
- (char*)cstring;

@end
