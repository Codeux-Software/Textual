
#import <Foundation/Foundation.h>

@interface NSData (BlowfishEncryptionDatHelper)
- (NSData *)repairedCharacterBufferForUTF8Encoding:(NSInteger *)badByteCount;
@end
