// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

#define _TXWindowToolbarHeight		25

@implementation TDChannelSheet

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"TDChannelSheet" owner:self];
	}

	return self;
}

#pragma mark -
#pragma mark NSToolbar Delegates

- (void)onMenuBarItemChanged:(id)sender 
{
	switch ([sender indexOfSelectedItem]) {
		case 0: [self firstPane:self.generalView]; break;
		case 1: [self firstPane:self.encryptView]; break;
        case 2: [self firstPane:self.defaultsView];  break;
		default: [self firstPane:self.generalView]; break;
	}
} 

- (void)firstPane:(NSView *)view 
{
	NSRect windowFrame = [self.sheet frame];
	
	windowFrame.size.width = [view frame].size.width;
	windowFrame.size.height = ([view frame].size.height + _TXWindowToolbarHeight);

	windowFrame.origin.y = (NSMaxY([self.sheet frame]) -
							([view frame].size.height + _TXWindowToolbarHeight));
	
	if (NSObjectIsNotEmpty([self.contentView subviews])) {
		[[self.contentView.subviews safeObjectAtIndex:0] removeFromSuperview];
	}
	
	[self.sheet setFrame:windowFrame display:YES animate:YES];
	
	[self.contentView setFrame:[view frame]];
	[self.contentView addSubview:view];	
	
	[self.sheet recalculateKeyViewLoop];
}

#pragma mark -
#pragma mark Initalization Handler

- (void)start
{
	[self load];
	[self update];
	[self startSheet];
	[self firstPane:self.generalView];
	
	[self.tabView setSelectedSegment:0];
}

- (void)show
{
	[self start];
}

- (void)close
{
	self.delegate = nil;
	
	[self endSheet];
}

- (void)load
{
	self.nameText.stringValue		= self.config.name;
	self.modeText.stringValue		= self.config.mode;
	self.topicText.stringValue		= self.config.topic;
	self.passwordText.stringValue	= self.config.password;
	self.encryptKeyText.stringValue = self.config.encryptionKey;
	
	self.growlCheck.state			= self.config.growl;
	self.autoJoinCheck.state		= self.config.autoJoin;
	self.ihighlights.state			= self.config.ignoreHighlights;
    self.JPQActivityCheck.state		= self.config.ignoreJPQActivity;
    self.inlineImagesCheck.state	= self.config.ignoreInlineImages;
}

- (void)save
{
	self.config.name			= self.nameText.stringValue;
	self.config.mode			= self.modeText.stringValue;
	self.config.topic			= self.topicText.stringValue;
	self.config.password		= self.passwordText.stringValue;
	self.config.encryptionKey	= self.encryptKeyText.stringValue;
    
	self.config.growl			= self.growlCheck.state;
	self.config.autoJoin		= self.autoJoinCheck.state;
    self.config.ignoreHighlights		= self.ihighlights.state;
    self.config.ignoreJPQActivity	= self.JPQActivityCheck.state;
    self.config.ignoreInlineImages	= self.inlineImagesCheck.state;
	
	if ([self.config.name isChannelName] == NO) {
		self.config.name = [@"#" stringByAppendingString:self.config.name];
	}
}

- (void)update
{
	if (self.cid > 0) {
		[self.nameText setEditable:NO];
	}
	
	NSString *s = self.nameText.stringValue;
	
	[self.okButton setEnabled:NSObjectIsNotEmpty(s)];
}

- (void)controlTextDidChange:(NSNotification *)note
{
	[self update];
}

#pragma mark -
#pragma mark Actions

- (void)ok:(id)sender
{
	[self save];
	
	if ([self.delegate respondsToSelector:@selector(channelSheetOnOK:)]) {
		[self.delegate channelSheetOnOK:self];
	}
	
	[self cancel:nil];
}

- (void)cancel:(id)sender
{
	[self endSheet];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.delegate respondsToSelector:@selector(channelSheetWillClose:)]) {
		[self.delegate channelSheetWillClose:self];
	}
}

@end