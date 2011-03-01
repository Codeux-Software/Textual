// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation FieldEditorTextView

@synthesize pasteDelegate;
@synthesize keyHandler;

- (id)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)aTextContainer
{
	if ((self = [super initWithFrame:frameRect textContainer:aTextContainer])) {
		keyHandler = [KeyEventHandler new];
	}
	
	return self;
}

- (void)dealloc
{
	[keyHandler drain];
	
	[super dealloc];
}

- (void)paste:(id)sender
{
	if (pasteDelegate) {
		if ([pasteDelegate fieldEditorTextViewPaste:self]) {
			return;
		}
	}
	
	NSWindow *awin = self.window;
	
	if ([awin hasAttachedSheet]) {
		[[awin selectedFieldEditor] paste:sender];
	} else {
		[super paste:sender];
	}
}

- (void)setKeyHandlerTarget:(id)target
{
	[keyHandler setTarget:target];
}

- (void)registerKeyHandler:(SEL)selector key:(NSInteger)code modifiers:(NSUInteger)mods
{
	[keyHandler registerSelector:selector key:code modifiers:mods];
}

- (void)registerKeyHandler:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods
{
	[keyHandler registerSelector:selector character:c modifiers:mods];
}

- (void)keyDown:(NSEvent *)e
{
	if ([keyHandler processKeyEvent:e]) {
		return;
	}
	
	[super keyDown:e];
}

@end