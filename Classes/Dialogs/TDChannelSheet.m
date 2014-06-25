/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

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

@interface TDChannelSheet ()
/* Each entry of the array is an array with index 0 equal to the
 view and index 1 equal to the first responder wanted in that view. */
@property (nonatomic, strong) NSArray *navigationTree;
@end

@implementation TDChannelSheet

- (id)init
{
	if ((self = [super init])) {
		[RZMainBundle() loadCustomNibNamed:@"TDChannelSheet" owner:self topLevelObjects:nil];
		
		_navigationTree = @[
			//    view				  first responder
			@[_generalView,			_channelNameField],
			@[_encryptionView,		_encryptionKeyField],
			@[_defaultsView,		_defaultTopicField],
		];
	}

	return self;
}

#pragma mark -
#pragma mark NSToolbar Delegates

- (void)onMenuBarItemChanged:(id)sender
{
	/* Get selected tab. */
	NSInteger row = [sender indexOfSelectedItem];
	
	/* Switch to that view. */
	[self firstPane:(_navigationTree[row][0])];
	
	/* Move to appropriate first responder. */
	[self.sheet makeFirstResponder:(_navigationTree[row][1])];
}

- (NSRect)currentSheetFrame
{
	return [self.sheet frame];
}

- (void)firstPane:(NSView *)view 
{
	/* Modify frame to match new view. */
	NSRect windowFrame = [self currentSheetFrame];
	
	windowFrame.size.width  =  view.frame.size.width;
	windowFrame.size.height = (view.frame.size.height + _TXWindowToolbarHeight);

	windowFrame.origin.y = (NSMaxY([self currentSheetFrame]) - windowFrame.size.height);
	
	/* Remove any old subviews. */
	NSArray *subviews = [_contentView subviews];
	
	if ([subviews count] > 0) {
		[subviews[0] removeFromSuperview];
	}
	
	/* Set new frame. */
	[self.sheet setFrame:windowFrame display:YES animate:YES];
	
	[_contentView setFrame:[view frame]];
	
	/* Add new view. */
	[_contentView addSubview:view];
	
	/* Reclaulate loop for tab key. */
	[self.sheet recalculateKeyViewLoop];
}

#pragma mark -
#pragma mark Initalization Handler

- (void)start
{
	[self load];
	[self update];
	
	[self startSheet];
	
	[_contentViewTabView setSelectedSegment:0];
	
	[self onMenuBarItemChanged:_contentViewTabView];
}

- (void)load
{
	[_channelNameField setStringValue:[_config channelName]];
	
	[_defaultModesField setStringValue:[_config defaultModes]];
	[_defaultTopicField setStringValue:[_config defaultTopic]];
	
	if ([_config encryptionKeyIsSet]) {
		[_encryptionKeyField setStringValue:[_config encryptionKeyValue]];
	}

	if ([_config secretKeyIsSet]) {
		[_secretKeyField setStringValue:[_config secretKeyValue]];
	}

	[_autoJoinCheck				setState:[_config autoJoin]];
	[_JPQActivityCheck			setState:[_config ignoreJPQActivity]];
	[_ignoreHighlightsCheck		setState:[_config ignoreHighlights]];
	[_pushNotificationsCheck	setState:[_config pushNotifications]];
	[_showTreeBadgeCountCheck	setState:[_config showTreeBadgeCount]];

	if ([TPCPreferences showInlineImages]) {
		[_disableInlineImagesCheck setState:[_config ignoreInlineImages]];
	} else {
		[_disableInlineImagesCheck setState:[_config ignoreInlineImages]];
	}
}

- (void)save
{
	[_config setChannelName:[_channelNameField firstTokenStringValue]];
	
	[_config setDefaultModes:[_defaultModesField trimmedStringValue]];
	[_config setDefaultTopic:[_defaultTopicField trimmedStringValue]];
	
	[_config setSecretKey:		[_secretKeyField firstTokenStringValue]];
	[_config setEncryptionKey:	[_encryptionKeyField trimmedStringValue]];
	
	[_config setAutoJoin:			[_autoJoinCheck state]];
	[_config setIgnoreJPQActivity:	[_JPQActivityCheck state]];
	[_config setIgnoreHighlights:	[_ignoreHighlightsCheck state]];
	[_config setPushNotifications:	[_pushNotificationsCheck state]];
	[_config setShowTreeBadgeCount:	[_showTreeBadgeCountCheck state]];

	if ([TPCPreferences showInlineImages]) {
		[_config setIgnoreInlineImages:[_disableInlineImagesCheck state]];
	} else {
		[_config setIgnoreInlineImages:[_enableInlineImagesCheck state]];
	}
	
	if ([[_config channelName] isChannelName] == NO) {
		 [_config setChannelName:[@"#" stringByAppendingString:[_config channelName]]];
	}
}

- (void)update
{
	NSString *s = [_channelNameField trimmedStringValue];
	
	[self.okButton setEnabled:[s isChannelName]];
	
	[_channelNameField setEditable:_newItem];
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
