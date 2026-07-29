#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

NSUserDefaults *KLDefaults(void);
UIWindow * _Nullable KLKeyWindow(void);
UIViewController * _Nullable KLTopViewController(void);
void KLPresentAlert(UIViewController *presenter, NSString *title, NSString *message);
void KLLog(NSString *format, ...) NS_FORMAT_FUNCTION(1,2);
BOOL KLClassNameMatches(id object, NSArray<NSString *> *names);
UIButton * _Nullable KLFindNativeUploadButton(UIView *rootView);

NS_ASSUME_NONNULL_END
