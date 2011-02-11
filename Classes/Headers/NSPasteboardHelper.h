// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface NSPasteboard (NSPasteboardHelper)
- (BOOL)hasStringContent;

- (NSString *)stringContent;
- (NSAttributedString *)attributedStringContent;

- (void)setStringContent:(NSString *)s;
- (void)setAttributedStringContent:(NSAttributedString *)s;
@end