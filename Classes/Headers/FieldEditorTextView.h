// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@interface FieldEditorTextView : NSTextView
{
	id pasteDelegate;
	id copyDelegate;
	
	KeyEventHandler *keyHandler;
}

@property (nonatomic, assign) id pasteDelegate;
@property (nonatomic, assign) id copyDelegate;
@property (nonatomic, retain) KeyEventHandler *keyHandler;

- (void)paste:(id)sender;
- (void)copy:(id)sender;

- (void)setKeyHandlerTarget:(id)target;
- (void)registerKeyHandler:(SEL)selector key:(NSInteger)code modifiers:(NSUInteger)mods;
- (void)registerKeyHandler:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods;
@end

@interface NSObject (FieldEditorTextViewDelegate)
- (void)fieldEditorTextViewPaste:(id)sender;
- (void)fieldEditorTextViewCopy:(id)sender;
@end