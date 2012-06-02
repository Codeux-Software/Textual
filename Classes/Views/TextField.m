// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation TextField

- (void)dealloc
{
	[_keyHandler drain];

	dispatch_release(_formattingQueue);
	_formattingQueue = NULL;
	
	[super dealloc];
}

- (id)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];

	if (self) {
		if ([Preferences rightToLeftFormatting]) {
			[self setBaseWritingDirection:NSWritingDirectionRightToLeft];
		} else {
            [self setBaseWritingDirection:NSWritingDirectionLeftToRight];
		}
        
        [super setTextContainerInset:NSMakeSize(DefaultTextFieldWidthPadding, DefaultTextFieldHeightPadding)];
        
        if (PointerIsEmpty(_keyHandler)) {
            _keyHandler = [KeyEventHandler new];
        }
        
        _formattingQueue = dispatch_queue_create("formattingQueue", NULL);
    }
	
    return self;
}

- (void)setKeyHandlerTarget:(id)target
{
	[_keyHandler setTarget:target];
}

- (void)registerKeyHandler:(SEL)selector key:(NSInteger)code modifiers:(NSUInteger)mods
{
	[_keyHandler registerSelector:selector key:code modifiers:mods];
}

- (void)registerKeyHandler:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods
{
	[_keyHandler registerSelector:selector character:c modifiers:mods];
}

- (void)keyDown:(NSEvent *)e
{
	if ([_keyHandler processKeyEvent:e]) {
		return;
	}
	
	[super keyDown:e];
}

- (dispatch_queue_t)formattingQueue
{
    return _formattingQueue;
}

- (NSAttributedString *)attributedStringValue
{
    return [self.attributedString.copy autodrain];
}

- (void)setAttributedStringValue:(NSAttributedString *)string
{
	NSData *stringData = [string RTFFromRange:NSMakeRange(0, [string length]) documentAttributes:nil];
    
    [self replaceCharactersInRange:[self fullSelectionRange] withRTF:stringData];
}

- (NSString *)stringValue
{
    return [self string];
}

- (void)setStringValue:(NSString *)string
{
    [self replaceCharactersInRange:[self fullSelectionRange] withString:string];
}

- (void)removeAttribute:(id)attr inRange:(NSRange)local
{
    [self.textStorage removeAttribute:attr range:local];
}

- (void)setAttributes:(id)attrs inRange:(NSRange)local
{
    [self.textStorage setAttributes:attrs range:local];
}

- (void)sanitizeTextField
{
	[self sanitizeIRCCompatibleAttributedString:DefaultTextFieldFont];
}

@end
