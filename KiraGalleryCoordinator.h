#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface KiraGalleryCoordinator : NSObject
+ (instancetype)sharedCoordinator;
- (void)openFromViewController:(UIViewController *)presenter;
@end

NS_ASSUME_NONNULL_END
