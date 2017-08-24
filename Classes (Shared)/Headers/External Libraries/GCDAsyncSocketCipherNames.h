
// See the contents of GCDAsyncSocketCipherNames.m for license information.

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, GCDAsyncSocketCipherSuiteVersion) {
	GCDAsyncSocketCipherSuiteDefaultVersion  	= 0,
	GCDAsyncSocketCipherSuite2015Version  		= 1,
	GCDAsyncSocketCipherSuite2017Version  		= 2,
	GCDAsyncSocketCipherSuiteNonePreferred		= 100
};

@interface GCDAsyncSocket (GCDsyncSocketCipherNamesExtension)
+ (nullable NSString *)descriptionForProtocolVersion:(SSLProtocol)protocolVersion;
+ (nullable NSString *)descriptionForCipherSuite:(SSLCipherSuite)cipherSuite;
+ (BOOL)isCipherSuiteDeprecated:(SSLCipherSuite)cipherSuite;

+ (NSArray<NSString *> *)descriptionsForCipherListVersion:(GCDAsyncSocketCipherSuiteVersion)version;
+ (NSArray<NSString *> *)descriptionsForCipherSuites:(NSArray<NSNumber *> *)cipherSuites;

+ (NSArray<NSNumber *> *)cipherListOfVersion:(GCDAsyncSocketCipherSuiteVersion)version;
+ (NSArray<NSNumber *> *)cipherListOfVersion:(GCDAsyncSocketCipherSuiteVersion)version
					includeDeprecatedCiphers:(BOOL)includeDepecatedCiphers;
@end

NS_ASSUME_NONNULL_END
