#import "KiraRuntime.h"
#import "KiraUtilities.h"
#import "KiraConstants.h"
#import "KiraSettingsViewController.h"
#import "KiraLockManager.h"
#import "KiraGalleryCoordinator.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <QuartzCore/QuartzCore.h>

static const void *KLSettingsButtonKey = &KLSettingsButtonKey;
static const void *KLGalleryButtonKey = &KLGalleryButtonKey;
static NSMutableDictionary<NSString *, NSValue *> *KLOriginalViewDidAppearIMPs;
static NSMutableSet<NSString *> *KLSettingsClassNames;
static NSMutableSet<NSString *> *KLCameraClassNames;

static NSString *KLRuntimeClassKey(Class cls) {
    return NSStringFromClass(cls) ?: @"<unknown>";
}

static IMP KLOriginalIMPForObject(id object) {
    Class cls = object_getClass(object);
    while (cls) {
        NSValue *value = KLOriginalViewDidAppearIMPs[KLRuntimeClassKey(cls)];
        if (value) return value.pointerValue;
        cls = class_getSuperclass(cls);
    }
    return NULL;
}

static void KLPresentSettings(UIViewController *presenter) {
    void (^show)(void) = ^{
        KiraSettingsViewController *settings = [[KiraSettingsViewController alloc] initWithStyle:UITableViewStyleInsetGrouped];
        UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:settings];
        navigation.modalPresentationStyle = UIModalPresentationFormSheet;
        [presenter presentViewController:navigation animated:YES completion:nil];
    };
    if ([KLDefaults() boolForKey:KLSettingsLockEnabledKey]) {
        [[KiraLockManager sharedManager] authenticateWithReason:@"Open KiraLocket settings" completion:^(BOOL success) {
            if (success) show();
        }];
    } else {
        show();
    }
}

static void KLSettingsButtonTapped(UIButton *button) {
    UIViewController *presenter = nil;
    UIResponder *responder = button;
    while (responder) {
        if ([responder isKindOfClass:UIViewController.class]) {
            presenter = (UIViewController *)responder;
            break;
        }
        responder = responder.nextResponder;
    }
    if (!presenter) presenter = KLTopViewController();
    if (presenter && !presenter.presentedViewController) KLPresentSettings(presenter);
}

static void KLGalleryButtonTapped(UIButton *button) {
    UIViewController *presenter = nil;
    UIResponder *responder = button;
    while (responder) {
        if ([responder isKindOfClass:UIViewController.class]) {
            presenter = (UIViewController *)responder;
            break;
        }
        responder = responder.nextResponder;
    }
    if (!presenter) presenter = KLTopViewController();
    if (!presenter) return;

    UIButton *nativeButton = KLFindNativeUploadButton(presenter.view);
    if (nativeButton && nativeButton != button && !nativeButton.hidden && nativeButton.alpha > 0.01 && nativeButton.userInteractionEnabled) {
        [nativeButton sendActionsForControlEvents:UIControlEventTouchUpInside];
        return;
    }

    [[KiraGalleryCoordinator sharedCoordinator] openFromViewController:presenter];
}

@interface KiraActionProxy : NSObject
+ (void)settingsTapped:(UIButton *)sender;
+ (void)galleryTapped:(UIButton *)sender;
@end

@implementation KiraActionProxy
+ (void)settingsTapped:(UIButton *)sender { KLSettingsButtonTapped(sender); }
+ (void)galleryTapped:(UIButton *)sender { KLGalleryButtonTapped(sender); }
@end

static UIButton *KLFloatingButton(NSString *symbol, NSString *accessibilityLabel) {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    button.translatesAutoresizingMaskIntoConstraints = NO;
    [button setImage:[UIImage systemImageNamed:symbol] forState:UIControlStateNormal];
    button.tintColor = UIColor.labelColor;
    button.backgroundColor = [UIColor.systemBackgroundColor colorWithAlphaComponent:0.92];
    button.layer.cornerRadius = 24;
    button.layer.shadowOpacity = 0.18;
    button.layer.shadowRadius = 8;
    button.layer.shadowOffset = CGSizeMake(0, 3);
    button.accessibilityLabel = accessibilityLabel;
    return button;
}

static void KLInstallSettingsButton(UIViewController *controller) {
    if (objc_getAssociatedObject(controller, KLSettingsButtonKey)) return;
    UIButton *button = KLFloatingButton(@"wand.and.stars", @"Open KiraLocket settings");
    [button addTarget:KiraActionProxy.class action:@selector(settingsTapped:) forControlEvents:UIControlEventTouchUpInside];
    [controller.view addSubview:button];
    UILayoutGuide *guide = controller.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [button.trailingAnchor constraintEqualToAnchor:guide.trailingAnchor constant:-14],
        [button.topAnchor constraintEqualToAnchor:guide.topAnchor constant:10],
        [button.widthAnchor constraintEqualToConstant:48],
        [button.heightAnchor constraintEqualToConstant:48]
    ]];
    objc_setAssociatedObject(controller, KLSettingsButtonKey, button, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void KLInstallGalleryButton(UIViewController *controller) {
    if (![KLDefaults() boolForKey:KLGalleryHelperEnabledKey]) return;
    if (objc_getAssociatedObject(controller, KLGalleryButtonKey)) return;
    UIButton *button = KLFloatingButton(@"photo.on.rectangle.angled", @"Open gallery helper");
    [button addTarget:KiraActionProxy.class action:@selector(galleryTapped:) forControlEvents:UIControlEventTouchUpInside];
    [controller.view addSubview:button];
    UILayoutGuide *guide = controller.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [button.leadingAnchor constraintEqualToAnchor:guide.leadingAnchor constant:16],
        [button.bottomAnchor constraintEqualToAnchor:guide.bottomAnchor constant:-78],
        [button.widthAnchor constraintEqualToConstant:48],
        [button.heightAnchor constraintEqualToConstant:48]
    ]];
    objc_setAssociatedObject(controller, KLGalleryButtonKey, button, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void KLHookedViewDidAppear(id self, SEL _cmd, BOOL animated) {
    IMP original = KLOriginalIMPForObject(self);
    if (original) ((void (*)(id, SEL, BOOL))original)(self, _cmd, animated);

    NSString *name = NSStringFromClass([self class]);
    if ([KLSettingsClassNames containsObject:name]) KLInstallSettingsButton((UIViewController *)self);
    if ([KLCameraClassNames containsObject:name]) KLInstallGalleryButton((UIViewController *)self);
}

static BOOL KLHookClass(Class cls, BOOL settingsClass, BOOL cameraClass) {
    if (!cls) return NO;
    NSString *name = KLRuntimeClassKey(cls);
    if (KLOriginalViewDidAppearIMPs[name]) return YES;

    SEL selector = @selector(viewDidAppear:);
    Method method = class_getInstanceMethod(cls, selector);
    if (!method) return NO;
    IMP original = method_getImplementation(method);
    const char *types = method_getTypeEncoding(method);

    BOOL added = class_addMethod(cls, selector, (IMP)KLHookedViewDidAppear, types);
    if (!added) method_setImplementation(class_getInstanceMethod(cls, selector), (IMP)KLHookedViewDidAppear);
    KLOriginalViewDidAppearIMPs[name] = [NSValue valueWithPointer:original];
    if (settingsClass) [KLSettingsClassNames addObject:name];
    if (cameraClass) [KLCameraClassNames addObject:name];
    KLLog(@"Hooked %@", name);
    return YES;
}

static Class KLFirstAvailableClass(NSArray<NSString *> *names) {
    for (NSString *name in names) {
        Class cls = NSClassFromString(name);
        if (cls) return cls;
    }
    return Nil;
}

@implementation KiraRuntime

+ (void)install {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        KLOriginalViewDidAppearIMPs = [NSMutableDictionary dictionary];
        KLSettingsClassNames = [NSMutableSet set];
        KLCameraClassNames = [NSMutableSet set];
        [[KiraLockManager sharedManager] start];

        NSArray<NSString *> *settingsNames = @[
            @"SettingsFeature.SettingsMenuSheetViewController",
            @"AppFeature.SettingsMenuSheetViewController",
            @"SettingsMenuSheetViewController",
            @"_TtC15SettingsFeature31SettingsMenuSheetViewController"
        ];
        NSArray<NSString *> *cameraNames = @[
            @"Camera.CameraViewController",
            @"_TtC6Camera20CameraViewController",
            @"CameraViewController"
        ];

        __block NSInteger attempts = 0;
        __block void (^attemptInstall)(void);
        attemptInstall = ^{
            attempts += 1;
            Class settingsClass = KLFirstAvailableClass(settingsNames);
            Class cameraClass = KLFirstAvailableClass(cameraNames);
            BOOL settingsOK = KLHookClass(settingsClass, YES, NO);
            BOOL cameraOK = KLHookClass(cameraClass, NO, YES);
            if ((!settingsOK || !cameraOK) && attempts < 15) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), attemptInstall);
            } else {
                KLLog(@"Installation finished: settings=%d camera=%d attempts=%ld", settingsOK, cameraOK, (long)attempts);
            }
        };
        dispatch_async(dispatch_get_main_queue(), attemptInstall);
    });
}

@end
