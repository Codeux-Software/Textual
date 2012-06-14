// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 08, 2012

@interface NSPasteboard (TXPasteboardHelper)
- (NSString *)stringContent;
- (void)setStringContent:(NSString *)s;
@end