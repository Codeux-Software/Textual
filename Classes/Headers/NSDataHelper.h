// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface NSData (TXDataHelper)
- (BOOL)isValidUTF8;

- (NSString *)validateUTF8;
- (NSString *)validateUTF8WithCharacter:(UniChar)malformChar;

- (NSString *)base64EncodingWithLineLength:(NSUInteger)lineLength;
@end