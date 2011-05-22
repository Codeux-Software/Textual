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
	[sheet drain];
	
	[super dealloc];
}

- (void)startSheet
{
	[self startSheetWithWindow:window];
}

- (void)startSheetWithWindow:(NSWindow *)awindow
{
	[[window fieldEditor:NO forObject:nil] setFieldEditor:NO];
	
	[NSApp beginSheet:sheet modalForWindow:awindow modalDelegate:self didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:) contextInfo:nil];
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