// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation SheetBase

@synthesize delegate;
@synthesize window;
@synthesize sheet;
@synthesize okButton;
@synthesize cancelButton;

- (void)dealloc
{
	[sheet release];
	[super dealloc];
}

- (void)startSheet
{
	[NSApp beginSheet:sheet modalForWindow:window modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
}

- (void)endSheet
{
	[NSApp endSheet:sheet];
}

- (void)sheetDidEnd:(NSWindow *)sender returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[sheet close];
}

- (void)ok:(id)sender
{
	[self endSheet];
}

- (void)cancel:(id)sender
{
	[self endSheet];
}

@end