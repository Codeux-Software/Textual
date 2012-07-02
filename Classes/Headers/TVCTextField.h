// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

#define TXDefaultTextFieldFontColor         [NSColor colorWithCalibratedWhite:0.15 alpha:1.0]
#define TXDefaultTextFieldFont              [NSFont fontWithName:@"Helvetica" size:12.0]

@interface TVCTextField : NSTextView 
@property (nonatomic, strong) TLOKeyEventHandler *keyHandler;
@property (nonatomic, assign) dispatch_queue_t formattingQueue;

- (BOOL)isAtTopOfView;
- (BOOL)isAtBottomOfView;

- (NSInteger)selectedLineNumber;
- (NSInteger)numberOfLines;

- (dispatch_queue_t)formattingQueue;

- (void)keyDownToSuper:(NSEvent *)e;
- (void)setKeyHandlerTarget:(id)target;
- (void)registerKeyHandler:(SEL)selector key:(NSInteger)code modifiers:(NSUInteger)mods;
- (void)registerKeyHandler:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods;

- (NSAttributedString *)attributedStringValue;
- (void)setAttributedStringValue:(NSAttributedString *)string;

- (NSString *)stringValue;
- (void)setStringValue:(NSString *)string;

- (void)sanitizeTextField:(BOOL)paste;

- (void)removeAttribute:(id)attr inRange:(NSRange)local;
- (void)setAttributes:(id)attrs inRange:(NSRange)local;
@end