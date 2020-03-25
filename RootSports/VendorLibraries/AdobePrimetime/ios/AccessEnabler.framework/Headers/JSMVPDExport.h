//
//  JSMVPDExport.h
//  AccessEnabler
//
//  Created by Adrian Silaghi on 05/08/2016.
//
//

#ifndef JSMVPDExport_h
#define JSMVPDExport_h

@import JavaScriptCore;

@protocol JSMVPDExport <JSExport>

@property (nonatomic, strong) NSString *ID;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *logoURL;
@property (nonatomic, strong) NSString *spUrl;
@property (nonatomic, assign) BOOL tempPass;

@end
#endif /* JSMVPDExport_h */
