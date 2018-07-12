
// See the contents of RCMSecureTransport.m for license information.

#import <Security/Security.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, RCMCipherSuiteCollection) {
	RCMCipherSuiteCollectionDefault  		= 0,
	RCMCipherSuiteCollectionMozilla2015  	= 1,
	RCMCipherSuiteCollectionMozilla2017  	= 2,
	RCMCipherSuiteCollectionNone			= 100
};

@interface RCMSecureTransport : NSObject
+ (nullable NSString *)descriptionForProtocolVersion:(SSLProtocol)protocolVersion;

+ (nullable NSString *)descriptionForCipherSuite:(SSLCipherSuite)cipherSuite;
+ (nullable NSString *)descriptionForCipherSuite:(SSLCipherSuite)cipherSuite withProtocol:(BOOL)appendProtocol;

+ (BOOL)isCipherSuiteDeprecated:(SSLCipherSuite)cipherSuite;

+ (NSArray<NSString *> *)descriptionsForCipherListCollection:(RCMCipherSuiteCollection)collection;
+ (NSArray<NSString *> *)descriptionsForCipherListCollection:(RCMCipherSuiteCollection)collection withProtocol:(BOOL)appendProtocol;

+ (NSArray<NSString *> *)descriptionsForCipherSuites:(NSArray<NSNumber *> *)cipherSuites;
+ (NSArray<NSString *> *)descriptionsForCipherSuites:(NSArray<NSNumber *> *)cipherSuites withProtocol:(BOOL)appendProtocol;

+ (NSArray<NSNumber *> *)cipherSuitesInCollection:(RCMCipherSuiteCollection)collection;
+ (NSArray<NSNumber *> *)cipherSuitesInCollection:(RCMCipherSuiteCollection)collection
								includeDeprecated:(BOOL)includeDepecated;

+ (BOOL)isTLSError:(NSError *)error;
+ (nullable NSString *)descriptionForError:(NSError *)error;
/* -descriptionForErrorCode: returns "Unknown" for out of range error codes */
+ (NSString *)descriptionForErrorCode:(NSInteger)errorCode;
+ (nullable NSString *)descriptionForBadCertificateError:(NSError *)error;
+ (nullable NSString *)descriptionForBadCertificateErrorCode:(NSInteger)errorCode;
+ (BOOL)isBadCertificateError:(NSError *)error;
+ (BOOL)isBadCertificateErrorCode:(NSInteger)errorCode;

+ (SecTrustRef)trustFromCertificateChain:(NSArray<NSData *> *)certificatecChain withPolicyName:(NSString *)policyName CF_RETURNS_RETAINED;

+ (nullable NSArray<NSData *> *)certificatesInTrust:(SecTrustRef)trustRef;
+ (nullable NSString *)policyNameInTrust:(SecTrustRef)trustRef;
@end

NS_ASSUME_NONNULL_END

