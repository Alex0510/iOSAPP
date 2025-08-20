#import <Foundation/Foundation.h>

#if __has_attribute(swift_private)
#define AC_SWIFT_PRIVATE __attribute__((swift_private))
#else
#define AC_SWIFT_PRIVATE
#endif

/// The "Avatar" asset catalog image resource.
static NSString * const ACImageNameAvatar AC_SWIFT_PRIVATE = @"Avatar";

/// The "appstore" asset catalog image resource.
static NSString * const ACImageNameAppstore AC_SWIFT_PRIVATE = @"appstore";

#undef AC_SWIFT_PRIVATE
