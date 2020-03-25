//
//  JSAEExport.h
//  AccessEnabler
//
//  Created by Adrian Silaghi on 03/08/2016.
//
//

#ifndef JSAEExport_h
#define JSAEExport_h

@import JavaScriptCore;

@protocol JSAEExport <JSExport>

NS_ASSUME_NONNULL_BEGIN

JSExportAs(setRequestor, - (void) setRequestor:(nonnull NSString *)requestorID);
JSExportAs(setRequestorAndServiceProviders, - (void) setRequestor:(nonnull NSString *)requestorID serviceProviders:(nullable NSArray *)urls);

- (void) checkAuthentication;
- (void) getAuthentication;
JSExportAs(getAuthenticationWithFilter, - (void) getAuthentication:(NSArray *)filter);
JSExportAs(getAuthenticationWithData, - (void) getAuthentication:(BOOL)forceAuthn withData:(nullable NSDictionary*)data);
JSExportAs(getAuthenticationWithDataAndFilter, - (void) getAuthentication:(BOOL)forceAuthn withData:(nullable NSDictionary*)data andFilter:(NSArray *)filter);
- (void) handleExternalURL:(NSString *)url;
JSExportAs(checkAuthorization, - (void) checkAuthorization:(nullable NSString *)resource);
JSExportAs(checkAuthorizationWithData, - (void) checkAuthorization:(NSString *)resource withData:(nullable NSDictionary*)data);
JSExportAs(getAuthorization, - (void) getAuthorization:(nullable NSString *)resource);
JSExportAs(getAuthorizationWithData, - (void) getAuthorization:(nullable NSString*)resource withData:(NSDictionary*)data);
JSExportAs(checkPreauthorizedResources, - (void) checkPreauthorizedResources:(nullable NSArray *)resources);
JSExportAs(checkPreauthorizedResourcesWithCache, - (void) checkPreauthorizedResources:(nullable NSArray *)resources cache:(BOOL)cache);
JSExportAs(setSelectedProvider, - (void) setSelectedProvider:(nullable NSString *)mvpdID);
- (void) getSelectedProvider;
JSExportAs(getMetadata, - (void) getMetadata:(nullable NSDictionary *)key);
- (void) logout;

NS_ASSUME_NONNULL_END

@end

#endif /* JSAEExport_h */
