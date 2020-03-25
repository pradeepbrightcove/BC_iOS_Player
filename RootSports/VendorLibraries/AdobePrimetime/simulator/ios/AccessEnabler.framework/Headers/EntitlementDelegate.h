/*************************************************************************
 * ADOBE CONFIDENTIAL
 * ___________________
 *
 *  Copyright 2014 Adobe Systems Incorporated
 *  All Rights Reserved.
 *
 * NOTICE:  All information contained herein is, and remains
 * the property of Adobe Systems Incorporated and its suppliers,
 * if any.  The intellectual and technical concepts contained
 * herein are proprietary to Adobe Systems Incorporated and its
 * suppliers and are protected by all applicable intellectual property laws,
 * including trade secret and copyright laws.
 * Dissemination of this information or reproduction of this material
 * is strictly forbidden unless prior written permission is obtained
 * from Adobe Systems Incorporated.
 ************************************************************************/

#import <Foundation/Foundation.h>
#import <VideoSubscriberAccount/VideoSubscriberAccount.h>
#import "Config.h"
#import "MVPD.h"

@class SFSafariViewController;

@protocol EntitlementDelegate <NSObject>

- (void) setRequestorComplete:(int)status;
- (void) setAuthenticationStatus:(int)status errorCode:(NSString *)code;
- (void) setToken:(NSString *)token forResource:(NSString *)resource;
- (void) preauthorizedResources:(NSArray *)resources;
- (void) tokenRequestFailed:(NSString *)resource errorCode:(NSString *)code errorDescription:(NSString *)description;
- (void) selectedProvider:(MVPD *)mvpd;
- (void) displayProviderDialog:(NSArray *)mvpds;
- (void) sendTrackingData:(NSArray *)data forEventType:(int)event;
- (void) setMetadataStatus:(id)metadata encrypted:(BOOL)encrypted forKey:(int)key andArguments:(NSDictionary *)arguments;
- (void) navigateToUrl:(NSString *)url;
- (void) presentTvProviderDialog:(UIViewController *) viewController;
- (void) dismissTvProviderDialog:(UIViewController *) viewController;

@optional
- (void) navigateToUrl:(NSString *)url useSVC:(BOOL)useSVC;

@end


