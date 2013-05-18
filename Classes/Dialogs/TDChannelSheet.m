/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

#define _TXWindowToolbarHeight			25

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
	NSInteger row = [sender indexOfSelectedItem];

	switch (row) {
		case 0:	{	[self firstPane:self.generalView]; break;		}
		case 1: {	[self firstPane:self.encryptionView]; break;	}
        case 2: {	[self firstPane:self.defaultsView]; break;		}
		default: {	[self firstPane:self.generalView]; break;		}
	}

	[self makeFirstResponderForRow:row];
}

- (void)makeFirstResponderForRow:(NSInteger)row
{
	switch (row) {
		case 0:	{	[self.window makeFirstResponder:self.channelNameField]; break;		}
		case 1: {	[self.window makeFirstResponder:self.encryptionKeyField]; break;	}
        case 2: {	[self.window makeFirstResponder:self.defaultTopicField]; break;		}
		default: { break; }
	}
}

- (void)firstPane:(NSView *)view 
{
	NSRect windowFrame = self.sheet.frame;
	
	windowFrame.size.width = view.frame.size.width;
	windowFrame.size.height = (view.frame.size.height + _TXWindowToolbarHeight);

	windowFrame.origin.y = (NSMaxY(self.sheet.frame) - windowFrame.size.height);
	
	if (NSObjectIsNotEmpty(self.contentView.subviews)) {
		[self.contentView.subviews[0] removeFromSuperview];
	}
	
	[self.sheet setFrame:windowFrame display:YES animate:YES];
	
	[self.contentView setFrame:view.frame];
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

	if (self.newItem) {
		[self.window makeFirstResponder:self.channelNameField];
	}
	
	[self.contentViewTabView setSelectedSegment:0];
}

- (void)load
{
	self.channelNameField.stringValue		= self.config.channelName;
	self.defaultModesField.stringValue		= self.config.defaultModes;
	self.defaultTopicField.stringValue		= self.config.defaultTopic;
	self.encryptionKeyField.stringValue		= self.config.encryptionKey;
	self.secretKeyField.stringValue			= self.config.secretKey;
	
	self.autoJoinCheck.state			= self.config.autoJoin;
	self.ignoreHighlightsCheck.state	= self.config.ignoreHighlights;
	self.pushNotificationsCheck.state	= self.config.pushNotifications;
    self.JPQActivityCheck.state			= self.config.ignoreJPQActivity;
    self.inlineImagesCheck.state		= self.config.ignoreInlineImages;
	self.showTreeBadgeCountCheck.state  = self.config.showTreeBadgeCount;
}

- (void)save
{
	self.config.channelName		= self.channelNameField.firstTokenStringValue;
	self.config.defaultModes	= self.defaultModesField.trimmedStringValue;
	self.config.defaultTopic	= self.defaultTopicField.trimmedStringValue;
	self.config.secretKey		= self.secretKeyField.firstTokenStringValue;
	self.config.encryptionKey	= self.encryptionKeyField.trimmedStringValue;
    
	self.config.autoJoin			= self.autoJoinCheck.state;
	self.config.showTreeBadgeCount  = self.showTreeBadgeCountCheck.state;
	self.config.pushNotifications	= self.pushNotificationsCheck.state;
    self.config.ignoreHighlights	= self.ignoreHighlightsCheck.state;
    self.config.ignoreInlineImages	= self.inlineImagesCheck.state;
    self.config.ignoreJPQActivity	= self.JPQActivityCheck.state;
	
	if ([self.config.channelName isChannelName] == NO) {
		self.config.channelName = [@"#" stringByAppendingString:self.config.channelName];
	}
}

- (void)update
{
	NSString *s = self.channelNameField.trimmedStringValue;
	
	[self.okButton setEnabled:[s isChannelName]];
	
	[self.channelNameField setEditable:self.newItem];
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
	
	[super ok:nil];
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
