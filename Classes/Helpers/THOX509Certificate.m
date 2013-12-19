//
//  THOX509Certificate.m
//  Main Project (Textual)
//
//  Created by Denis Dzyubenko on 24/11/13.
//  Copyright (c) 2013 Codeux Software. All rights reserved.
//

#import "THOX509Certificate.h"
#import <openssl/x509.h>

static NSString *field(X509_NAME *name, const char *txt)
{
    int nid = OBJ_txt2nid(txt);
    int index = X509_NAME_get_index_by_NID(name, nid, -1);
    X509_NAME_ENTRY *entry = X509_NAME_get_entry(name, index);
    if (entry) {
        ASN1_STRING *issuerNameASN1 = X509_NAME_ENTRY_get_data(entry);
        if (issuerNameASN1) {
            unsigned char *issuerName = ASN1_STRING_data(issuerNameASN1);
            return [NSString stringWithUTF8String:(char *)issuerName];
        }
    }
    return nil;
}

static NSDate *asn1time_to_nsdate(ASN1_TIME *asn1time)
{
    ASN1_GENERALIZEDTIME *asn1generalizedtime = ASN1_TIME_to_generalizedtime(asn1time, NULL);
    if (asn1generalizedtime) {
        unsigned char *certificateExpiryData = ASN1_STRING_data(asn1generalizedtime);

        // ASN1 generalized times look like this: "20131114230046Z"
        //                                format:  YYYYMMDDHHMMSS
        //                               indices:  01234567890123
        //                                                   1111
        // There are other formats (e.g. specifying partial seconds or
        // time zones) but this is good enough for our purposes since
        // we only use the date and not the time.
        //
        // (Source: http://www.obj-sys.com/asn1tutorial/node14.html)

        NSString *expiryTimeStr = [NSString stringWithUTF8String:(char *)certificateExpiryData];
        NSDateComponents *expiryDateComponents = [[NSDateComponents alloc] init];

        expiryDateComponents.year   = [[expiryTimeStr substringWithRange:NSMakeRange(0, 4)] intValue];
        expiryDateComponents.month  = [[expiryTimeStr substringWithRange:NSMakeRange(4, 2)] intValue];
        expiryDateComponents.day    = [[expiryTimeStr substringWithRange:NSMakeRange(6, 2)] intValue];
        expiryDateComponents.hour   = [[expiryTimeStr substringWithRange:NSMakeRange(8, 2)] intValue];
        expiryDateComponents.minute = [[expiryTimeStr substringWithRange:NSMakeRange(10, 2)] intValue];
        expiryDateComponents.second = [[expiryTimeStr substringWithRange:NSMakeRange(12, 2)] intValue];

        NSCalendar *calendar = [NSCalendar currentCalendar];
        return [calendar dateFromComponents:expiryDateComponents];
    }
    return nil;
}

static NSDate *notBefore(X509 *certificateX509)
{
    ASN1_TIME *asn1time = X509_get_notBefore(certificateX509);
    return asn1time_to_nsdate(asn1time);
}

static NSDate *notAfter(X509 *certificateX509)
{
    ASN1_TIME *asn1time = X509_get_notAfter(certificateX509);
    return asn1time_to_nsdate(asn1time);
}

@implementation THOX509CertificateObject
@end

@implementation THOX509Certificate

- (instancetype)initWithDER:(NSData *)data
{
    self = [super init];
    if (self) {
        const unsigned char *bytes = (const unsigned char *)data.bytes;
        X509 *x509cert = d2i_X509(NULL, &bytes, data.length);

        _issuer = [[THOX509CertificateObject alloc] init];
        X509_NAME *issuerX509Name = X509_get_issuer_name(x509cert);
        if (issuerX509Name) {
            _issuer.commonName = field(issuerX509Name, "CN");
            _issuer.country = field(issuerX509Name, "C");
            _issuer.stateOrProvince = field(issuerX509Name, "ST");
            _issuer.location = field(issuerX509Name, "L");
            _issuer.organizationalUnitName = field(issuerX509Name, "OU");
            _issuer.organizationName = field(issuerX509Name, "O");
        }

        _subject = [[THOX509CertificateObject alloc] init];
        X509_NAME *subjectX509Name = X509_get_subject_name(x509cert);
        if (subjectX509Name) {
            _subject.commonName = field(subjectX509Name, "CN");
            _subject.country = field(subjectX509Name, "C");
            _subject.stateOrProvince = field(subjectX509Name, "ST");
            _subject.location = field(subjectX509Name, "L");
            _subject.organizationalUnitName = field(subjectX509Name, "OU");
            _subject.organizationName = field(subjectX509Name, "O");
        }

        _notBefore = notBefore(x509cert);
        _notAfter = notAfter(x509cert);

        ASN1_INTEGER *serialNumberX509 = X509_get_serialNumber(x509cert);
        unsigned char *serialNumberData = ASN1_STRING_data(serialNumberX509);
        int serialNumberLength = ASN1_STRING_length(serialNumberX509);
        _serial = [NSData dataWithBytes:serialNumberData length:serialNumberLength];
    }
    return self;
}

@end
