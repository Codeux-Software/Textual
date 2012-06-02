// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define DefaultTextFieldFontColor           [NSColor colorWithCalibratedWhite:0.15 alpha:1.0]
#define DefaultTextFieldFont                [NSFont fontWithName:@"Helvetica" size:12.0]
#define DefaultTextFieldWidthPadding		1.0
#define DefaultTextFieldHeightPadding		6.0

@class KeyEventHandler;

@interface TextField : NSTextView 
{
	KeyEventHandler *_keyHandler;
    
    dispatch_queue_t _formattingQueue;
}

- (dispatch_queue_t)formattingQueue;

- (void)setKeyHandlerTarget:(id)target;
- (void)registerKeyHandler:(SEL)selector key:(NSInteger)code modifiers:(NSUInteger)mods;
- (void)registerKeyHandler:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods;

- (NSAttributedString *)attributedStringValue;
- (void)setAttributedStringValue:(NSAttributedString *)string;

- (NSString *)stringValue;
- (void)setStringValue:(NSString *)string;

- (void)sanitizeTextField;

- (void)removeAttribute:(id)attr inRange:(NSRange)local;
- (void)setAttributes:(id)attrs inRange:(NSRange)local;
@end