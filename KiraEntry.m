#import <Foundation/Foundation.h>
#import "KiraRuntime.h"

__attribute__((constructor)) static void KiraLocketEntry(void) {
    @autoreleasepool {
        NSString *bundleID = NSBundle.mainBundle.bundleIdentifier;
        if ([bundleID isEqualToString:@"com.locket.Locket"]) {
            [KiraRuntime install];
        }
    }
}
