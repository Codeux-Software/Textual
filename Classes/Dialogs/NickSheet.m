// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NickSheet

@synthesize uid;
@synthesize currentText;
@synthesize nicknameNewInfo;

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"NickSheet" owner:self];
	}

	return self;
}

- (void)start:(NSString *)nick
{
	[nicknameNewInfo setStringValue:nick];
	[currentText setStringValue:nick];
	
	[sheet makeFirstResponder:nicknameNewInfo];
	
	[self startSheet];
}

- (void)ok:(id)sender
{
	if ([delegate respondsToSelector:@selector(nickSheet:didInputNick:)]) {
		[delegate nickSheet:self didInputNick:nicknameNewInfo.stringValue];
	}
	
	[super ok:sender];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([delegate respondsToSelector:@selector(nickSheetWillClose:)]) {
		[delegate nickSheetWillClose:self];
	}
}

@end