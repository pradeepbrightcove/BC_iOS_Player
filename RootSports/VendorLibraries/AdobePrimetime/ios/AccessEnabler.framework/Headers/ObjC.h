//
//  ObjC.h
//  AccessEnabler
//
//  Created by asilaghi on 19/08/2016.
//
//

#ifndef ObjC_h
#define ObjC_h

@interface ObjC : NSObject

+ (BOOL)catchException:(void(^)(void))tryBlock error:(__autoreleasing NSError **)error;

@end

#endif /* ObjC_h */
