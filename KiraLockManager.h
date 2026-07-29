#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KiraLockManager : NSObject
+ (instancetype)sharedManager;
- (void)start;
- (void)authenticateWithReason:(NSString *)reason completion:(void (^)(BOOL success))completion;
- (void)refreshLockState;
@end

NS_ASSUME_NONNULL_END
