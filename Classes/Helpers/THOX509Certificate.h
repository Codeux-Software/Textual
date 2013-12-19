//
//  THOX509Certificate.h
//  Main Project (Textual)
//
//  Created by Denis Dzyubenko on 24/11/13.
//  Copyright (c) 2013 Codeux Software. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface THOX509CertificateObject : NSObject

@property (nonatomic, strong) NSString *commonName;             // CN
@property (nonatomic, strong) NSString *organizationName;       //  O
@property (nonatomic, strong) NSString *country;                //  C
@property (nonatomic, strong) NSString *stateOrProvince;        // ST
@property (nonatomic, strong) NSString *location;               //  L
@property (nonatomic, strong) NSString *organizationalUnitName; // OU

@end

@interface THOX509Certificate : NSObject

@property (nonatomic, strong) THOX509CertificateObject *issuer;
@property (nonatomic, strong) THOX509CertificateObject *subject;
@property (nonatomic, strong) NSData *serial;

@property (nonatomic, strong) NSDate *notBefore;
@property (nonatomic, strong) NSDate *notAfter;

- (instancetype)initWithDER:(NSData *)data;

@end
