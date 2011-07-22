// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class KeyEventHandler;

@interface TextField : NSTextView 
{
    BOOL _fontResetRequired;
    BOOL _lastChangeWasPaste;
    
	KeyEventHandler *_keyHandler;
}

- (void)setKeyHandlerTarget:(id)target;
- (void)registerKeyHandler:(SEL)selector key:(NSInteger)code modifiers:(NSUInteger)mods;
- (void)registerKeyHandler:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods;

- (NSAttributedString *)attributedStringValue;
- (void)setAttributedStringValue:(NSAttributedString *)string;

- (NSString *)stringValue;
- (void)setStringValue:(NSString *)string;

- (void)removeAttribute:(id)attr inRange:(NSRange)local;
- (void)setAttributes:(id)attrs inRange:(NSRange)local;

- (void)toggleFontResetStatus:(BOOL)status;
- (void)resetTextFieldFont:(id)defaultFont color:(id)defaultColor;
- (void)textDidChange:(id)sender pasted:(BOOL)paste range:(NSRange)erange;
@end