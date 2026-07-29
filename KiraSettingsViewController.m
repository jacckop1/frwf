#import "KiraSettingsViewController.h"
#import "KiraConstants.h"
#import "KiraUtilities.h"
#import "KiraLockManager.h"

@interface KiraSettingsViewController ()
@property (nonatomic, copy) NSArray<NSArray<NSDictionary *> *> *rows;
@end

@implementation KiraSettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"KiraLocket";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                           target:self
                                                                                           action:@selector(doneTapped)];
    self.rows = @[
        @[
            @{ @"title": @"App Lock", @"subtitle": @"Require Face ID, Touch ID, or passcode after leaving the app.", @"key": KLAppLockEnabledKey },
            @{ @"title": @"Settings Lock", @"subtitle": @"Authenticate before opening this settings page.", @"key": KLSettingsLockEnabledKey },
            @{ @"title": @"Gallery Helper", @"subtitle": @"Show a camera shortcut. It mirrors Locket's visible native upload action; otherwise it opens the system share sheet.", @"key": KLGalleryHelperEnabledKey },
            @{ @"title": @"Diagnostics", @"subtitle": @"Write compatibility messages to the device log.", @"key": KLDiagnosticsEnabledKey }
        ],
        @[
            @{ @"title": @"Compatibility", @"subtitle": @"Tested statically against Locket 2.56.1. Runtime class discovery supports Camera.CameraViewController and SettingsFeature.SettingsMenuSheetViewController." },
            @{ @"title": @"Privacy", @"subtitle": @"All preferences are local. This tweak contains no licensing, telemetry, account export, or network requests." },
            @{ @"title": @"Limits", @"subtitle": @"It does not unlock Gold, hide ads, alter purchases, spoof subscriptions, or bypass Locket server checks." }
        ]
    ];
}

- (void)doneTapped {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    (void)tableView;
    return self.rows.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    (void)tableView;
    return self.rows[section].count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    (void)tableView;
    return section == 0 ? @"Features" : @"About";
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *row = self.rows[indexPath.section][indexPath.row];
    NSString *key = row[@"key"];
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"KiraCell"];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"KiraCell"];
        cell.detailTextLabel.numberOfLines = 0;
    }
    cell.textLabel.text = row[@"title"];
    cell.detailTextLabel.text = row[@"subtitle"];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    if (key) {
        UISwitch *toggle = [UISwitch new];
        toggle.on = [KLDefaults() boolForKey:key];
        toggle.accessibilityIdentifier = key;
        [toggle addTarget:self action:@selector(toggleChanged:) forControlEvents:UIControlEventValueChanged];
        cell.accessoryView = toggle;
    } else {
        cell.accessoryView = nil;
    }
    return cell;
}

- (void)toggleChanged:(UISwitch *)sender {
    NSString *key = sender.accessibilityIdentifier;
    if (!key.length) return;
    [KLDefaults() setBool:sender.isOn forKey:key];
    [KLDefaults() synchronize];
    if ([key isEqualToString:KLAppLockEnabledKey]) {
        [[KiraLockManager sharedManager] refreshLockState];
    }
}

@end
