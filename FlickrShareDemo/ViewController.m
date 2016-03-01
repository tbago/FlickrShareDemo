//
//  ViewController.m
//  FlickrShareDemo
//
//  Created by tbago on 16/2/29.
//  Copyright © 2016年 tbago. All rights reserved.
//

#import "ViewController.h"
#import <MBProgressHUD.h>
#import <FlickrKit/FlickrKit.h>
#import <FBKVOController.h>

#import "FlickrShareKey.h"
#import "FlickrAuthViewController.h"

@interface ViewController () <UIActionSheetDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate>
///<Flick share
@property (nonatomic, retain) FKDUNetworkOperation              *completeAuthOperation;
@property (nonatomic, retain) FKDUNetworkOperation              *checkAuthOperation;
@property (nonatomic, retain) FKImageUploadNetworkOperation     *uploadOperation;
@property (strong, nonatomic) MBProgressHUD                     *flickrExportProgressHUD;
@property (strong, nonatomic) FBKVOController                   *KVOController;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.KVOController = [FBKVOController controllerWithObserver:self];
}


- (IBAction)shareImageToFlickrButtonClick:(UIButton *)sender {
    [self sharedImageToFlickr];
}

#pragma mark - Image Select
- (void)selectImageToUpload {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.delegate = self;
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagePicker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    imagePicker.allowsEditing = YES;
    [self presentViewController:imagePicker animated:YES completion:nil];
}

#pragma marks -- UIImagePickerControllerDelegate --
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [self dismissViewControllerAnimated:YES completion:nil];
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.image"]) {
        UIImage *originImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        [self sharedImageToFlickrInternal:originImage];
    }
}

#pragma mark - Flickr
- (void)sharedImageToFlickr {
    self.checkAuthOperation = [[FlickrKit sharedFlickrKit] checkAuthorizationOnCompletion:^(NSString *userName, NSString *userId, NSString *fullName, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error && userId.length > 0) {
                [self selectImageToUpload];
            }
            else {
                [self flickrUserLogin];
            }
        });
    }];
}

- (void)flickrUserLogin {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(flickrUserAuthenticateCallback:) name:kFlickrAuthCallBackNotificationName object:nil];
    
    FlickrAuthViewController *flickrAuthViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"FlickrAuthViewController"];
    [self.navigationController pushViewController:flickrAuthViewController animated:YES];
}

- (void)sharedImageToFlickrInternal:(UIImage *) sharedImage {
    self.flickrExportProgressHUD.mode = MBProgressHUDModeDeterminateHorizontalBar;
    self.flickrExportProgressHUD.progress = 0.0;
    self.flickrExportProgressHUD.labelText = NSLocalizedString(@"Sharing...", nil);
    [self.flickrExportProgressHUD show:YES];
    NSDictionary *uploadArgs = @{@"title": @"Yuneec FlyingCamera", @"description": @"A Photo from Yuneec FlyingCamera", @"is_public": @"1", @"is_friend": @"0", @"is_family": @"0", @"hidden": @"2"};
    self.uploadOperation =  [[FlickrKit sharedFlickrKit] uploadImage:sharedImage args:uploadArgs completion:^(NSString *imageID, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                self.flickrExportProgressHUD.mode = MBProgressHUDModeIndeterminate;
                self.flickrExportProgressHUD.labelText = error.localizedDescription;
            } else {
                self.flickrExportProgressHUD.mode = MBProgressHUDModeIndeterminate;
                self.flickrExportProgressHUD.labelText = NSLocalizedString(@"Share to Flickr success", nil);
            }
            [self.flickrExportProgressHUD hide:YES afterDelay:2.0];
        });
    }];
    
    [self.KVOController observe:self.uploadOperation keyPath:@"uploadProgress" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew block:^(id observer, id object, NSDictionary *change) {
        self.flickrExportProgressHUD.progress = [change[@"new"] floatValue];
    }];
}

- (void)flickrUserAuthenticateCallback:(NSNotification *)notification {
    NSURL *callbackURL = notification.object;
    self.completeAuthOperation = [[FlickrKit sharedFlickrKit] completeAuthWithURL:callbackURL completion:^(NSString *userName, NSString *userId, NSString *fullName, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                [self sharedImageToFlickr];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];
            }
            [self.navigationController popToViewController:self animated:YES];
        });
    }];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kFlickrAuthCallBackNotificationName object:nil];
}

- (MBProgressHUD *)flickrExportProgressHUD {
    if (_flickrExportProgressHUD == nil) {
        _flickrExportProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:_flickrExportProgressHUD];
        
        _flickrExportProgressHUD.color = [[UIColor darkGrayColor] colorWithAlphaComponent:0.49];
        _flickrExportProgressHUD.removeFromSuperViewOnHide = NO;
        _flickrExportProgressHUD.mode = MBProgressHUDModeDeterminateHorizontalBar;
        _flickrExportProgressHUD.labelText = NSLocalizedString(@"Sharing...", nil);
    }
    return _flickrExportProgressHUD;
}
@end
