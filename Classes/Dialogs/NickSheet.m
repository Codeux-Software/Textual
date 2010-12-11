// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "NickSheet.h"

@implementation NickSheet

@synthesize uid;
@synthesize currentText;
@synthesize newText;

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"NickSheet" owner:self];
	}
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)start:(NSString*)nick
{
	[currentText setStringValue:nick];
	[newText setStringValue:nick];
	[sheet makeFirstResponder:newText];
	
	[self startSheet];
}

- (void)ok:(id)sender
{
	if ([delegate respondsToSelector:@selector(nickSheet:didInputNick:)]) {
		[delegate nickSheet:self didInputNick:newText.stringValue];
	}
	
	[super ok:sender];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
	if ([delegate respondsToSelector:@selector(nickSheetWillClose:)]) {
		[delegate nickSheetWillClose:self];
	}
}

@end