
// See the contents of GCDAsyncSocketCipherNames.m for license information.

NS_ASSUME_NONNULL_BEGIN

@interface GCDAsyncSocket (GCDsyncSocketCipherNamesExtension)
@property (readonly, copy, nullable) NSString *sslNegotiatedProtocolString;
@property (readonly, copy, nullable) NSString *sslNegotiatedCipherSuiteString;
@property (readonly) BOOL sslConnectedWithDeprecatedCipher;

+ (NSArray<NSNumber *> *)cipherList;
@end

NS_ASSUME_NONNULL_END
