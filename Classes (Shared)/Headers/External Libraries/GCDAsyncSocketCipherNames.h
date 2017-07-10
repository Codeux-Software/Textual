
// See the contents of GCDAsyncSocketCipherNames.m for license information.

NS_ASSUME_NONNULL_BEGIN

@interface GCDAsyncSocket (GCDsyncSocketCipherNamesExtension)
+ (nullable NSString *)descriptionForProtocolVersion:(SSLProtocol)protocolVersion;
+ (nullable NSString *)descriptionForCipherSuite:(SSLCipherSuite)cipherSuite;
+ (BOOL)isCipherSuiteDeprecated:(SSLCipherSuite)cipherSuite;

+ (NSArray<NSNumber *> *)cipherList;
@end

NS_ASSUME_NONNULL_END
