// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 09, 2012

#import "TextualApplication.h"

@implementation TDCNickSheet

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"TDCNickSheet" owner:self];
	}

	return self;
}

- (void)start:(NSString *)nick
{
	[self.nicknameNewInfo setStringValue:nick];
	[self.currentText setStringValue:nick];
	
	[self.sheet makeFirstResponder:self.nicknameNewInfo];
	
	[self startSheet];
}

- (void)ok:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(nickSheet:didInputNick:)]) {
		[self.delegate nickSheet:self didInputNick:self.nicknameNewInfo.stringValue];
	}
	
	[super ok:sender];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.delegate respondsToSelector:@selector(nickSheetWillClose:)]) {
		[self.delegate nickSheetWillClose:self];
	}
}

@end