// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface NSData (NSDataHelper)
- (BOOL)isValidUTF8;
- (NSString *)validateUTF8;
- (NSString *)validateUTF8WithCharacter:(UniChar)malformChar;
- (NSString *)base64EncodingWithLineLength:(NSUInteger)lineLength;
@end