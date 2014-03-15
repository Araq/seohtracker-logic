#import "NSObject+seohyun.h"

@implementation NSObject (seohyun)

/// Shortcut for NSStringFromClass()
- (NSString*)class_string
{
	return NSStringFromClass([self class]);
}

@end
