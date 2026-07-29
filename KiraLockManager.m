#import "KiraLockManager.h"
#import "KiraUtilities.h"
#import "KiraConstants.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import <QuartzCore/QuartzCore.h>

@interface KiraLockManager ()
@property (nonatomic, strong, nullable) UIView *overlay;
@property (nonatomic, assign) BOOL sessionUnlocked;
@property (nonatomic, assign) BOOL authenticationInProgress;
@end

@implementation KiraLockManager

+ (instancetype)sharedManager {
    static KiraLockManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ manager = [KiraLockManager new]; });
    return manager;
}

- (void)start {
    NSNotificationCenter *center = NSNotificationCenter.defaultCenter;
    [center addObserver:self selector:@selector(applicationDidBecomeActive:)
                   name:UIApplicationDidBecomeActiveNotification object:nil];
    [center addObserver:self selector:@selector(applicationWillResignActive:)
                   name:UIApplicationWillResignActiveNotification object:nil];
    dispatch_async(dispatch_get_main_queue(), ^{ [self refreshLockState]; });
}

- (void)applicationDidBecomeActive:(NSNotification *)notification {
    (void)notification;
    dispatch_async(dispatch_get_main_queue(), ^{ [self refreshLockState]; });
}

- (void)applicationWillResignActive:(NSNotification *)notification {
    (void)notification;
    if ([KLDefaults() boolForKey:KLAppLockEnabledKey]) {
        self.sessionUnlocked = NO;
    }
}

- (void)refreshLockState {
    if (![KLDefaults() boolForKey:KLAppLockEnabledKey]) {
        self.sessionUnlocked = YES;
        [self removeOverlay];
        return;
    }
    if (self.sessionUnlocked) {
        [self removeOverlay];
        return;
    }
    [self showOverlay];
}

- (void)showOverlay {
    if (self.overlay.superview) return;
    UIWindow *window = KLKeyWindow();
    if (!window) return;

    UIVisualEffectView *blur = [[UIVisualEffectView alloc] initWithEffect:[UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemChromeMaterial]];
    blur.frame = window.bounds;
    blur.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    blur.accessibilityIdentifier = @"KiraLocket.LockOverlay";

    UIView *content = blur.contentView;
    UIImageView *icon = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"lock.shield.fill"]];
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    icon.contentMode = UIViewContentModeScaleAspectFit;
    icon.tintColor = UIColor.labelColor;

    UILabel *title = [UILabel new];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"KiraLocket Locked";
    title.font = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle2];
    title.textAlignment = NSTextAlignmentCenter;

    UILabel *subtitle = [UILabel new];
    subtitle.translatesAutoresizingMaskIntoConstraints = NO;
    subtitle.text = @"Use Face ID, Touch ID, or the device passcode.";
    subtitle.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    subtitle.textColor = UIColor.secondaryLabelColor;
    subtitle.numberOfLines = 0;
    subtitle.textAlignment = NSTextAlignmentCenter;

    UIButton *unlock = [UIButton buttonWithType:UIButtonTypeSystem];
    unlock.translatesAutoresizingMaskIntoConstraints = NO;
    [unlock setTitle:@"Unlock" forState:UIControlStateNormal];
    unlock.titleLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleHeadline];
    unlock.backgroundColor = UIColor.systemBackgroundColor;
    unlock.layer.cornerRadius = 14.0;
    unlock.contentEdgeInsets = UIEdgeInsetsMake(13, 28, 13, 28);
    [unlock addTarget:self action:@selector(unlockTapped:) forControlEvents:UIControlEventTouchUpInside];

    [content addSubview:icon];
    [content addSubview:title];
    [content addSubview:subtitle];
    [content addSubview:unlock];

    [NSLayoutConstraint activateConstraints:@[
        [icon.centerXAnchor constraintEqualToAnchor:content.centerXAnchor],
        [icon.centerYAnchor constraintEqualToAnchor:content.centerYAnchor constant:-95],
        [icon.widthAnchor constraintEqualToConstant:58],
        [icon.heightAnchor constraintEqualToConstant:58],
        [title.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:18],
        [title.leadingAnchor constraintGreaterThanOrEqualToAnchor:content.leadingAnchor constant:24],
        [title.trailingAnchor constraintLessThanOrEqualToAnchor:content.trailingAnchor constant:-24],
        [title.centerXAnchor constraintEqualToAnchor:content.centerXAnchor],
        [subtitle.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:10],
        [subtitle.leadingAnchor constraintEqualToAnchor:content.leadingAnchor constant:40],
        [subtitle.trailingAnchor constraintEqualToAnchor:content.trailingAnchor constant:-40],
        [unlock.topAnchor constraintEqualToAnchor:subtitle.bottomAnchor constant:24],
        [unlock.centerXAnchor constraintEqualToAnchor:content.centerXAnchor]
    ]];

    [window addSubview:blur];
    self.overlay = blur;
}

- (void)unlockTapped:(UIButton *)sender {
    (void)sender;
    [self authenticateWithReason:@"Unlock KiraLocket" completion:^(BOOL success) {
        if (!success) return;
        self.sessionUnlocked = YES;
        [self removeOverlay];
    }];
}

- (void)authenticateWithReason:(NSString *)reason completion:(void (^)(BOOL))completion {
    if (self.authenticationInProgress) return;
    self.authenticationInProgress = YES;
    LAContext *context = [LAContext new];
    context.localizedCancelTitle = @"Cancel";
    NSError *error = nil;
    LAPolicy policy = LAPolicyDeviceOwnerAuthentication;
    if (![context canEvaluatePolicy:policy error:&error]) {
        self.authenticationInProgress = NO;
        dispatch_async(dispatch_get_main_queue(), ^{
            KLPresentAlert(KLTopViewController(), @"Authentication unavailable", error.localizedDescription ?: @"Set a device passcode first.");
            if (completion) completion(NO);
        });
        return;
    }
    [context evaluatePolicy:policy localizedReason:reason reply:^(BOOL success, NSError * _Nullable authError) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.authenticationInProgress = NO;
            if (!success && authError.code != LAErrorUserCancel && authError.code != LAErrorSystemCancel) {
                KLLog(@"Authentication failed: %@", authError.localizedDescription);
            }
            if (completion) completion(success);
        });
    }];
}

- (void)removeOverlay {
    [self.overlay removeFromSuperview];
    self.overlay = nil;
}

@end
