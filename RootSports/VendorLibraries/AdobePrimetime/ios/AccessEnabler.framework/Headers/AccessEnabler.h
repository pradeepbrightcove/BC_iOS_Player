/*************************************************************************
 * ADOBE CONFIDENTIAL
 * ___________________
 *
 *  Copyright 2016 Adobe Systems Incorporated
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
#import "AccessEnablerConstants.h"
#import "EntitlementDelegate.h"
#import "EntitlementStatus.h"
#import "JSAEExport.h"
#import "ObjC.h"

#define MOCK_CONTEXT_COMPONENTS @"mockContextComponents"
#define MOCK_WEB_VIEW @"mockWebView"
#if TARGET_OS_IOS
@import SafariServices;
#endif

@class ClientAuthentication;

@interface AccessEnabler : NSObject<JSAEExport> {
    id <EntitlementDelegate> __weak delegate;
    id <EntitlementStatus> __weak statusDelegate;

@private
    NSMutableArray *pendingCalls;
    NSMutableArray *pendingAuthorizationsRequests;
    NSMutableDictionary *authorizationRequestCachedStatuses;
    BOOL isAuthenticationTokenCached;
    BOOL isAuthenticatingFlag;
    NSDictionary *options;
}

@property (weak, nullable) id<EntitlementDelegate> delegate;
@property (weak, nullable) id<EntitlementStatus> statusDelegate;

@property (nonatomic, retain, nonnull) NSString *svcRedirectURL;

// use this method to initialize the AccessEnabler
- (nonnull id) init:(nonnull NSString *)softwareStatement;
- (void) setOptions:(nonnull NSDictionary *)options;
- (void) setRequestor:(nonnull NSString *)requestorID;
- (void) setRequestor:(nonnull NSString *)requestorID serviceProviders:(nullable NSArray *)urls;
- (void) checkAuthentication;

- (void) getAuthentication;
- (void) getAuthentication:(nullable NSDictionary *)filter;
- (void) getAuthentication:(BOOL)forceAuthn withData:(nullable NSDictionary*)data;
- (void) getAuthentication:(BOOL)forceAuthn withData:(nullable NSDictionary*)data andFilter:(nullable NSDictionary *)filter;
- (void) handleExternalURL:(nullable NSString *)url;
- (void) checkAuthorization:(nullable NSString *)resource;
- (void) checkAuthorization:(nullable NSString *)resource withData:(nullable NSDictionary *)data;
- (void) getAuthorization:(nullable NSString *)resource;
- (void) getAuthorization:(nullable NSString *)resource withData:(nullable NSDictionary *)data;
- (void) checkPreauthorizedResources:(nullable NSArray *)resources;
- (void) checkPreauthorizedResources:(nullable NSArray *)resources cache:(BOOL)cache;
- (void) setSelectedProvider:(nullable NSString *)mvpdID;
- (void) getSelectedProvider;
- (void) getMetadata:(nullable NSDictionary *)key;
- (void) logout;

- (void)dispatchStatus:(nullable NSDictionary *)statusDict;

@end
