// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@implementation TDCTopicSheet

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"TDCTopicSheet" owner:self];
	}

	return self;
}

- (void)start:(NSString *)topic
{
	TXMenuController *menu = self.delegate;

	IRCChannel *c = [menu.world selectedChannel];
	
	NSString *nheader;
	
	nheader = [self.header stringValue];
	nheader = [NSString stringWithFormat:nheader, c.name];
	
	[menu.master.formattingMenu enableSheetField:self.text];
    
	[self.header setStringValue:nheader];
	
	[self.text setAttributedStringValue:[topic attributedStringWithIRCFormatting:TXDefaultTextFieldFont
													  followFormattingPreference:NO]];
    
	[self startSheet];
}

- (void)ok:(id)sender
{
	if ([self.delegate respondsToSelector:@selector(topicSheet:onOK:)]) {  
		NSString *topicv;
		NSArray  *topicc;

		topicv = [self.text.attributedStringValue attributedStringToASCIIFormatting];
		topicc = [topicv componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
		topicv = [topicc componentsJoinedByString:NSStringWhitespacePlaceholder];
		
		[self.delegate topicSheet:self onOK:topicv];
	}
	
	[super ok:nil];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	[[self.delegate master].formattingMenu enableWindowField:[self.delegate master].text];
	
	if ([self.delegate respondsToSelector:@selector(topicSheetWillClose:)]) {
		[self.delegate topicSheetWillClose:self];
	}
}

@end
