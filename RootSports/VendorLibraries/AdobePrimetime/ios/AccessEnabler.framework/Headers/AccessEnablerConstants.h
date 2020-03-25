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

#import "ClientVersion.h"

#define SP_SAML_PRODUCTION                      @"https://saml.sp.auth.adobe.com"
#define SP_SAML_STAGING                         @"https://saml.sp.auth-staging.adobe.com"
#define SP_AUTH_PRODUCTION                      @"sp.auth.adobe.com/adobe-services"
#define SP_AUTH_STAGING                         @"sp.auth-staging.adobe.com/adobe-services"
// TODO : fix this
#define API_PRODUCTION                          @"api.auth.adobe.com"
#define API_STAGING                             @"api.auth-staging.adobe.com"

#define SP_URL_AUTH                             @"/adobe-services"
#define SP_URL_ERROR                            @"/errors"

#define DEFAULT_SP_URL SP_AUTH_PRODUCTION

#define AUTHZ_HANDLED_ERROR_CODES               [NSArray arrayWithObjects:@"invalid",@"authzNone",@"network",nil]

#pragma mark - AdobePass web-service paths
#define SP_URL_DOMAIN_NAME                      @"adobe.com"
#define SP_URL_PATH_SET_REQUESTOR               @"/config/"
#define SP_URL_PATH_GET_AUTHENTICATION          @"/authenticate/saml"
#define SP_URL_PATH_GET_AUTHENTICATION_TOKEN    @"/sessionDevice"
#define SP_URL_PATH_GET_AUTHORIZATION_TOKEN     @"/authorizeDevice"
#define SP_URL_PATH_GET_SHORT_MEDIA_TOKEN       @"/deviceShortAuthorize"
#define SP_URL_PATH_LOGOUT                      @"/logout"
#define SP_URL_PATH_GET_DEVICEID_METADATA       @"/getMetadataDevice"
#define SP_URL_PATH_GET_ENCRYPTED_USER_METADATA @"/usermetadata"
#define SP_URL_IDENTIFIER_PASSIVE_AUTHN         @"/completePassiveAuthentication"
#define SP_URL_PATH_CHECK_PREAUTHZ_RESOURCES    @"/preauthorize"
#define SP_URL_PATH_TOKEN_EXCHANGE              @"/tokens"
#define SP_URL_PATH_VERIFICATION_CODE           @"/tokens/verificationCode"

#define CLIENTLESS_POLL_TIMER_INTERVAL  ((int) 10)
#define CLIENTLESS_REGCODE_TTL ((int) 1800)
#define HTTP_RETRY_LIMIT ((int) 1)

#define CUSTOM_SCHEME_PREFIX                    @"adbe."
#define ADOBEPASS_REDIRECT_SCHEME               @"adobepass://"
#define ADOBEPASS_REDIRECT_URL                  (ADOBEPASS_REDIRECT_SCHEME @"ios.app")

#if TARGET_OS_TV
#define CLIENT_TYPE                         @"tvOS"
#else
#define CLIENT_TYPE                         @"iOS"
#endif

#define CLIENT_TYPE_AIR                         @"AIR_iOS"

#pragma mark - AccessEnabler status codes
#define ACCESS_ENABLER_STATUS_ERROR             0
#define ACCESS_ENABLER_STATUS_SUCCESS           1

#pragma mark - AccessEnabler error codes
#define USER_AUTHENTICATED                      @""
#define USER_NOT_AUTHENTICATED_ERROR            @"User Not Authenticated Error"
#define HANDLED_USER_NOT_AUTHORIZED_ERROR       @"Handled User Not Authorized Error"
#define USER_NOT_AUTHORIZED_ERROR               @"User Not Authorized Error"
#define PROVIDER_NOT_SELECTED_ERROR             @"Provider Not Selected Error"
#define GENERIC_AUTHENTICATION_ERROR            @"Generic Authentication Error"
#define GENERIC_AUTHORIZATION_ERROR             @"Generic Authorization Error"
#define SERVER_API_TOO_OLD                      @"API Version too old. Please update your application."

#pragma mark - getMetadata operation codes
#define METADATA_AUTHENTICATION                 0
#define METADATA_AUTHORIZATION                  1
#define METADATA_DEVICE_ID                      2
#define METADATA_USER_META                      3
#define METADATA_KEY_INVALID                    255
#define METADATA_OPCODE_KEY                     @"opCode"
#define METADATA_RESOURCE_ID_KEY                @"resource_id"
#define METADATA_USER_META_KEY                  @"user_metadata_name"

#pragma mark - sendTrackingData event types
#define TRACKING_AUTHENTICATION                 0
#define TRACKING_AUTHORIZATION                  1
#define TRACKING_MVPD_SELECTION                 2

#pragma mark - sendTrackingData return values
#define TRACKING_NONE                           @"None"
#define TRACKING_YES                            @"YES"
#define TRACKING_NO                             @"NO"

#define OPTION_PROFILE              @"applicationProfile"
#define OPTION_VISITOR_ID           @"visitorID"
#define OPTION_HANDLE_SVC           @"handleSVC"
