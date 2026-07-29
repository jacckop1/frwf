#import "KiraUtilities.h"
#import "KiraConstants.h"
#import <objc/runtime.h>

NSUserDefaults *KLDefaults(void) {
    static NSUserDefaults *defaults;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaults = [[NSUserDefaults alloc] initWithSuiteName:KLDefaultsSuite];
        [defaults registerDefaults:@{
            KLAppLockEnabledKey: @NO,
            KLSettingsLockEnabledKey: @NO,
            KLGalleryHelperEnabledKey: @YES,
            KLDiagnosticsEnabledKey: @NO
        }];
    });
    return defaults;
}

UIWindow *KLKeyWindow(void) {
    UIApplication *application = UIApplication.sharedApplication;
    for (UIScene *scene in application.connectedScenes) {
        if (scene.activationState != UISceneActivationStateForegroundActive ||
            ![scene isKindOfClass:UIWindowScene.class]) {
            continue;
        }
        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *window in windowScene.windows) {
            if (window.isKeyWindow) return window;
        }
        for (UIWindow *window in windowScene.windows) {
            if (!window.hidden && window.alpha > 0.0) return window;
        }
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    return application.keyWindow;
#pragma clang diagnostic pop
}

static UIViewController *KLTopFromController(UIViewController *controller) {
    if (!controller) return nil;
    if (controller.presentedViewController) {
        return KLTopFromController(controller.presentedViewController);
    }
    if ([controller isKindOfClass:UINavigationController.class]) {
        return KLTopFromController(((UINavigationController *)controller).visibleViewController);
    }
    if ([controller isKindOfClass:UITabBarController.class]) {
        return KLTopFromController(((UITabBarController *)controller).selectedViewController);
    }
    return controller;
}

UIViewController *KLTopViewController(void) {
    return KLTopFromController(KLKeyWindow().rootViewController);
}

void KLPresentAlert(UIViewController *presenter, NSString *title, NSString *message) {
    if (!presenter) presenter = KLTopViewController();
    if (!presenter || presenter.presentedViewController) return;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [presenter presentViewController:alert animated:YES completion:nil];
}

void KLLog(NSString *format, ...) {
    if (![KLDefaults() boolForKey:KLDiagnosticsEnabledKey]) return;
    va_list args;
    va_start(args, format);
    NSString *message = [[NSString alloc] initWithFormat:format arguments:args];
    va_end(args);
    NSLog(@"[KiraLocket] %@", message);
}

BOOL KLClassNameMatches(id object, NSArray<NSString *> *names) {
    if (!object) return NO;
    NSString *runtimeName = NSStringFromClass([object class]);
    for (NSString *candidate in names) {
        if ([runtimeName isEqualToString:candidate] || [runtimeName hasSuffix:candidate]) return YES;
    }
    return NO;
}

static BOOL KLControlHasUploadAction(UIControl *control) {
    for (id target in control.allTargets) {
        NSArray<NSString *> *actions = [control actionsForTarget:target forControlEvent:UIControlEventTouchUpInside];
        for (NSString *action in actions) {
            NSString *lower = action.lowercaseString;
            if ([lower containsString:@"tappeduploadphoto"] ||
                ([lower containsString:@"upload"] && [lower containsString:@"photo"])) {
                return YES;
            }
        }
    }
    return NO;
}

UIButton *KLFindNativeUploadButton(UIView *rootView) {
    if (!rootView) return nil;
    NSMutableArray<UIView *> *queue = [NSMutableArray arrayWithObject:rootView];
    while (queue.count > 0) {
        UIView *view = queue.firstObject;
        [queue removeObjectAtIndex:0];
        if ([view isKindOfClass:UIButton.class]) {
            UIButton *button = (UIButton *)view;
            NSString *combined = [NSString stringWithFormat:@"%@ %@ %@",
                                  button.accessibilityLabel ?: @"",
                                  [button titleForState:UIControlStateNormal] ?: @"",
                                  button.accessibilityIdentifier ?: @""].lowercaseString;
            BOOL labelMatch = [combined containsString:@"upload"] ||
                              [combined containsString:@"gallery"] ||
                              [combined containsString:@"photo library"] ||
                              [combined containsString:@"المعرض"] ||
                              [combined containsString:@"رفع"];
            if (labelMatch || KLControlHasUploadAction(button)) return button;
        }
        [queue addObjectsFromArray:view.subviews];
    }
    return nil;
}
