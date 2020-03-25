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
#import "JSMVPDExport.h"


@interface MVPD : NSObject<JSMVPDExport> {
    
@private
    NSString *ID;
    NSString *displayName;
    NSString *logoURL;
    NSString *spUrl;
    NSString *spBaseUrl;
}

@property (nonatomic, strong) NSString *ID;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *logoURL;
@property (nonatomic, strong) NSString *spUrl;
@property (nonatomic, strong) NSString *spBaseUrl;
@property (nonatomic, assign) BOOL hasAuthNPerRequestor;
@property (nonatomic, assign) BOOL passiveAuthnEnabled;
@property (nonatomic, assign) BOOL tempPass;
@property (nonatomic, assign) BOOL enablePlatformServices;
@property (nonatomic, assign) BOOL enforcePlatformPermissions;
@property (nonatomic, assign) BOOL displayInPlatformPicker;
@property (nonatomic, strong) NSString *boardingStatus;
@property (nonatomic, strong) NSString *platformMappingId;
@property (nonatomic, strong) NSMutableArray *requiredMetadataFields;
@property (nonatomic, assign) BOOL useSVC;

- (NSString *)toString;

- (NSString *)description;

@end
