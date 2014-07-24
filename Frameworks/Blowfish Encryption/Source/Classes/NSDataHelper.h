
/*
 This source file contains work created by a third-party developer.
 
 The piece of the source file in question is the method defenition for
 the method call -repairedCharacterBufferForUTF8Encoding.
 
 The original license is as follows:
 
 // Author: Oleg Andreev <oleganza@gmail.com>
 // May 28, 2011
 // Do What The Fuck You Want Public License <http://www.wtfpl.net>
 
 https://gist.github.com/oleganza/997155
 */

#import <Foundation/Foundation.h>

@interface NSData (BlowfishEncryptionDatHelper)
- (NSData *)repairedCharacterBufferForUTF8Encoding:(NSInteger *)badByteCount;
@end
