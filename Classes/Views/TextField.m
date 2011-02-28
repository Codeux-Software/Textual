// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation TextField

@synthesize _oldInputValue;
@synthesize _oldTextColor;
@synthesize _usesCustomUndoManager;

- (void)dealloc
{
	if (_usesCustomUndoManager) {
		[_oldInputValue drain];
	}
	
	[_oldTextColor drain];
	
	[super dealloc];
}

- (void)setFontColor:(NSColor *)color
{
	[_oldTextColor drain];
	_oldTextColor = nil;
	
	_oldTextColor = [[self textColor] retain];
	
	[self setTextColor:color];
}

- (void)removeAllUndoActions
{
	if (_usesCustomUndoManager) {
		[[self undoManager] removeAllActions];
	}
}

- (void)setUsesCustomUndoManager:(BOOL)customManager
{
	if (_usesCustomUndoManager) {
		if (customManager == NO) {
			[_oldInputValue drain];
			_oldInputValue = nil;
			
			[[self undoManager] removeAllActionsWithTarget:self];
			[[self.window selectedFieldEditor] setAllowsUndo:YES];
			
			_usesCustomUndoManager = NO;
		}
	} else {
		if (customManager) {
			_oldInputValue = [@"" retain];
			
			[[self undoManager] removeAllActionsWithTarget:self];
			[[self.window selectedFieldEditor] setAllowsUndo:NO];
			
			_usesCustomUndoManager = YES;
		}
	}
}

- (void)setObjectValue:(id)obj recordUndo:(BOOL)undo
{
	if (_usesCustomUndoManager) {
		[_oldInputValue drain];
		_oldInputValue = nil;
		
		_oldInputValue = [[self objectValue] retain];
		
		NSUndoManager *undoMan = [self undoManager];
		
		if ([undoMan canUndo] == NO) {
			[[undoMan prepareWithInvocationTarget:self] setObjectValue:@"" recordUndo:YES];
		}
		
		if (undo && [obj isEqual:_oldInputValue] == NO) {
			[[undoMan prepareWithInvocationTarget:self] setObjectValue:_oldInputValue recordUndo:YES];
		}
	}
	
	[super setObjectValue:obj];
}

- (void)setStringValue:(NSString *)aString
{
	[self setObjectValue:aString recordUndo:YES];
}

- (void)setAttributedStringValue:(NSAttributedString *)obj
{
	[self setObjectValue:obj recordUndo:YES];
}

- (void)setFilteredAttributedStringValue:(NSAttributedString *)string
{
	string = [string sanitizeIRCCompatibleAttributedString:[self textColor] 
												  oldColor:_oldTextColor 
										   backgroundColor:[self backgroundColor] 
											   defaultFont:[self font]];
	
	string = [string attributedStringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]];
	
	[super setObjectValue:string];
}

- (void)pasteFilteredAttributedString:(NSRange)selectedRange
{
	NSText *currentEditor = [self currentEditor];
	
	NSData   *rtfData = [_NSPasteboard() dataForType:NSRTFPboardType];
	NSString *rawData = [_NSPasteboard() stringContent];
	
	if (PointerIsEmpty(rtfData) == NO || PointerIsEmpty(rawData) == NO) {
		id newString = [NSMutableAttributedString alloc];
		id oldString = [[self attributedStringValue] mutableCopy];
		
		NSString *currentValue = [self stringValue];
		
		[oldString autodrain];
		
		if (PointerIsEmpty(rtfData) == NO) {
			if ([currentValue hasPrefix:@"/"] == NO) {
				newString = [[newString initWithRTF:rtfData documentAttributes:nil] autodrain];
			} else {
				newString = [[newString initWithString:rawData] autodrain];
			}
		} else {
			newString = [[newString initWithString:rawData] autodrain];
		}
		
		if (PointerIsEmpty(newString) == NO) {
			NSRange frontChop;
			
			newString = [newString sanitizeNSLinkedAttributedString:[self textColor]];
			newString = [newString sanitizeIRCCompatibleAttributedString:[self textColor]
																oldColor:_oldTextColor
														 backgroundColor:[self backgroundColor]
															 defaultFont:[self font]];
			
			if (selectedRange.length >= 1) {
				[oldString replaceCharactersInRange:selectedRange withString:[newString string]];
			} else {
				[oldString insertAttributedString:newString atIndex:selectedRange.location];
			}
			
			oldString = [oldString attributedStringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet] frontChop:&frontChop];
			
			[self setObjectValue:oldString recordUndo:YES];
			
			NSInteger finalLength = [(NSMutableAttributedString *)newString length];
			
			selectedRange.length    = 0;
			selectedRange.location += finalLength;
			
			if (frontChop.location != NSNotFound) {
				selectedRange.location -= frontChop.location;
			}
			
			if (selectedRange.location > finalLength) {
				[self focus];
			} else {
				[currentEditor setSelectedRange:selectedRange];
			}
		}
	}
}

- (void)textDidChange:(NSNotification *)notification
{
	if (_usesCustomUndoManager) {
		NSUndoManager *undoMan = [self undoManager];
		
		if ([undoMan canUndo] == NO) {
			[[undoMan prepareWithInvocationTarget:self] setObjectValue:@"" recordUndo:YES];
		}
		
		id newValue = [self objectValue];
		
		if ([newValue isEqual:_oldInputValue] == NO) {
			[[undoMan prepareWithInvocationTarget:self] setObjectValue:_oldInputValue recordUndo:YES];
		}
		
		[_oldInputValue drain];
		_oldInputValue = nil;
		
		_oldInputValue = [[self objectValue] retain];
		
		[super setObjectValue:_oldInputValue];
	}
}

@end