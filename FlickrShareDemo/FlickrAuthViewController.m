//
//  FlickrAuthViewController.m
//  FlickrShareDemo
//
//  Created by tbago on 16/3/1.
//  Copyright © 2016年 tbago. All rights reserved.
//

#import "FlickrAuthViewController.h"
#import <FlickrKit/FlickrKit.h>

@interface FlickrAuthViewController ()

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView    *activityIndicatorView;
@property (weak, nonatomic) IBOutlet UIWebView                  *webView;

@property (nonatomic, retain) FKDUNetworkOperation              *authOperation;

@end

@implementation FlickrAuthViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Flickr Auth";
    
    // This must be defined in your Info.plist
    // See FlickrKitDemo-Info.plist
    // Flickr will call this back. Ensure you configure your flickr app as a web app
    NSString *callbackURLString = @"FlickrShareDemo://auth";
    
    // Begin the authentication process
    self.authOperation = [[FlickrKit sharedFlickrKit] beginAuthWithCallbackURL:[NSURL URLWithString:callbackURLString] permission:FKPermissionDelete completion:^(NSURL *flickrLoginPageURL, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error) {
                NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:flickrLoginPageURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];
                [self.webView loadRequest:urlRequest];
            } else {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:error.localizedDescription delegate:nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
                [alert show];
            }
        });
    }];
}

#pragma mark - action
- (IBAction)backButtonClick:(UIButton *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    //If they click NO DONT AUTHORIZE, this is where it takes you by default... maybe take them to my own web site, or show something else
    NSURL *url = [request URL];
    // If it's the callback url, then lets trigger that
    if (![url.scheme isEqual:@"http"] && ![url.scheme isEqual:@"https"]) {
        if ([[UIApplication sharedApplication]canOpenURL:url]) {
            [[UIApplication sharedApplication]openURL:url];
            return NO;
        }
    }
    return YES;
    
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [self.activityIndicatorView stopAnimating];
}

@end
