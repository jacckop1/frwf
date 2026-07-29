#import "KiraGalleryCoordinator.h"
#import "KiraUtilities.h"
#import <PhotosUI/PhotosUI.h>
#import <Photos/Photos.h>

@interface KiraGalleryCoordinator () <PHPickerViewControllerDelegate>
@property (nonatomic, weak, nullable) UIViewController *presenter;
@end

@implementation KiraGalleryCoordinator

+ (instancetype)sharedCoordinator {
    static KiraGalleryCoordinator *coordinator;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ coordinator = [KiraGalleryCoordinator new]; });
    return coordinator;
}

- (void)openFromViewController:(UIViewController *)presenter {
    if (!presenter || presenter.presentedViewController) return;
    self.presenter = presenter;
    PHPickerConfiguration *configuration = [[PHPickerConfiguration alloc] initWithPhotoLibrary:[PHPhotoLibrary sharedPhotoLibrary]];
    configuration.selectionLimit = 1;
    configuration.filter = [PHPickerFilter anyFilterMatchingSubfilters:@[[PHPickerFilter imagesFilter], [PHPickerFilter videosFilter]]];
    PHPickerViewController *picker = [[PHPickerViewController alloc] initWithConfiguration:configuration];
    picker.delegate = self;
    [presenter presentViewController:picker animated:YES completion:nil];
}

- (void)picker:(PHPickerViewController *)picker didFinishPicking:(NSArray<PHPickerResult *> *)results {
    [picker dismissViewControllerAnimated:YES completion:nil];
    PHPickerResult *result = results.firstObject;
    if (!result) return;
    NSItemProvider *provider = result.itemProvider;

    if ([provider canLoadObjectOfClass:UIImage.class]) {
        [provider loadObjectOfClass:UIImage.class completionHandler:^(UIImage * _Nullable image, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (!image || error) {
                    KLPresentAlert(self.presenter, @"Unable to load image", error.localizedDescription ?: @"Unknown error");
                    return;
                }
                [self presentShareItems:@[image] title:@"Selected image"];
            });
        }];
        return;
    }

    NSString *movieType = @"public.movie";
    if ([provider hasItemConformingToTypeIdentifier:movieType]) {
        [provider loadFileRepresentationForTypeIdentifier:movieType completionHandler:^(NSURL * _Nullable url, NSError * _Nullable error) {
            if (!url || error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    KLPresentAlert(self.presenter, @"Unable to load video", error.localizedDescription ?: @"Unknown error");
                });
                return;
            }
            NSString *filename = url.lastPathComponent.length ? url.lastPathComponent : @"KiraLocket-video.mov";
            NSURL *copyURL = [NSURL fileURLWithPath:[NSTemporaryDirectory() stringByAppendingPathComponent:filename]];
            [[NSFileManager defaultManager] removeItemAtURL:copyURL error:nil];
            NSError *copyError = nil;
            [[NSFileManager defaultManager] copyItemAtURL:url toURL:copyURL error:&copyError];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (copyError) {
                    KLPresentAlert(self.presenter, @"Unable to prepare video", copyError.localizedDescription);
                    return;
                }
                [self presentShareItems:@[copyURL] title:@"Selected video"];
            });
        }];
    }
}

- (void)presentShareItems:(NSArray *)items title:(NSString *)title {
    UIViewController *presenter = self.presenter ?: KLTopViewController();
    if (!presenter || presenter.presentedViewController) return;
    UIActivityViewController *activity = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    activity.title = title;
    if (activity.popoverPresentationController) {
        activity.popoverPresentationController.sourceView = presenter.view;
        activity.popoverPresentationController.sourceRect = CGRectMake(CGRectGetMidX(presenter.view.bounds), CGRectGetMidY(presenter.view.bounds), 1, 1);
    }
    [presenter presentViewController:activity animated:YES completion:nil];
}

@end
