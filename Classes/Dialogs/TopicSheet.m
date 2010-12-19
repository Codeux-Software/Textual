// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TopicSheet.h"

@implementation TopicSheet

@synthesize uid;
@synthesize cid;
@synthesize text;

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"TopicSheet" owner:self];
	}
	return self;
}

- (void)dealloc
{
	[super dealloc];
}

- (void)start:(NSString *)topic
{
	[text setStringValue:[topic stringWithInputIRCFormatting] ?: @""];
	[self startSheet];
}

- (void)ok:(id)sender
{
	if ([delegate respondsToSelector:@selector(topicSheet:onOK:)]) {
		[delegate topicSheet:self onOK:[[text stringValue] stringWithASCIIFormatting]];
	}
	
	[super ok:nil];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([delegate respondsToSelector:@selector(topicSheetWillClose:)]) {
		[delegate topicSheetWillClose:self];
	}
}

@end