
// See the contents of GCDAsyncSocketCipherNames.m for license information.

#import "TextualApplication.h"

@interface GCDAsyncSocket (GCDsyncSocketCipherNamesExtension)
@property (readonly, copy) NSString *sslNegotiatedProtocolString;
@property (readonly, copy) NSString *sslNegotiatedCipherSuiteString;
@end
