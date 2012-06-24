// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "TextualApplication.h"

@implementation TDCSheetBase

- (void)startSheet
{
	[self startSheetWithWindow:self.window];
}

- (void)startSheetWithWindow:(NSWindow *)awindow
{
	[[self.window fieldEditor:NO forObject:nil] setFieldEditor:NO];
	
	[NSApp beginSheet:self.sheet
	   modalForWindow:awindow
		modalDelegate:self
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];
}

- (void)endSheet
{
	[NSApp endSheet:self.sheet];
}

- (void)sheetDidEnd:(NSWindow *)sender
		 returnCode:(NSInteger)returnCode
		contextInfo:(void *)contextInfo
{
	[self.sheet close];
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