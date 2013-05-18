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

@implementation TDCHighlightEntrySheet

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"TDCHighlightEntrySheet" owner:self];
	}

	return self;
}

- (void)controlTextDidChange:(NSNotification *)obj
{
	[self updateSaveButton];
}

- (void)start
{
	/* Start populating. */
	if (NSObjectIsNotEmpty(self.config.matchKeyword)) {
		self.matchKeywordTextField.stringValue = self.config.matchKeyword;
	}

	if (self.config.matchIsExcluded) {
		[self.matchTypePopupButton selectItemWithTag:2];
	} else {
		[self.matchTypePopupButton selectItemWithTag:1];
	}

	/* Exact word matching mode does not use exclude words. Therefore,
	 if we are in that mode, we have to inform the end user. We do that
	 by disabling the exclude menu item that they can select and showing
	 one with a message explaining this instead. */

	NSMenuItem *normalExclude = [self.matchTypePopupButton itemAtIndex:1];
	NSMenuItem *specialExclude = [self.matchTypePopupButton itemAtIndex:2];

	if ([TPCPreferences highlightMatchingMethod] == TXNicknameHighlightExactMatchType) {
		[normalExclude setHidden:YES];
		
		[specialExclude setHidden:NO];
		[specialExclude setEnabled:NO];
	} else {
		[normalExclude setHidden:NO];
		[specialExclude setHidden:YES];
	}

	/* Channel list. */
	IRCClient *client = [self.worldController findClientById:self.clientID];

	if (PointerIsEmpty(client) || client.channels.count <= 0) {
		/* If we have nothing, hide the menu divider under "All Channels" */
		
		[self.matchChannelPopupButton removeItemAtIndex:1];
	} else {
		/* Start populating channels. */
		for (IRCChannel *channel in client.channels) {
			[self.matchChannelPopupButton addItemWithTitle:channel.name];

			/* Select the channel with matching IDs. */
			if ([channel.config.itemUUID isEqualToString:self.config.matchChannelID]) {
				[self.matchChannelPopupButton selectItemWithTitle:channel.name];
			}
		}
	}

	/* Pop the sheet. */
	[self startSheet];

	[self.window makeFirstResponder:self.matchKeywordTextField];

	[self updateSaveButton];
}

- (void)ok:(id)sender
{
	/* Save keyword. */
	self.config.matchKeyword = self.matchKeywordTextField.stringValue;

	/* Channel. */
	NSInteger selectedItem = self.matchChannelPopupButton.indexOfSelectedItem;

	NSString *selectedTitle = self.matchChannelPopupButton.titleOfSelectedItem;

	BOOL zeroOutChannel = YES;

	if (selectedItem > 0) { // 0 = ALL CHANNELS
		IRCClient *client = [self.worldController findClientById:self.clientID];

		if (client) {
			IRCChannel *channel = [client findChannel:selectedTitle];

			if (channel) {
				zeroOutChannel = NO;
				
				self.config.matchChannelID = channel.config.itemUUID;
			}
		}
	}

	if (zeroOutChannel) {
		self.config.matchChannelID = NSStringEmptyPlaceholder;
	}

	/* Entry type. */
	self.config.matchIsExcluded = (self.matchTypePopupButton.selectedTag == 2);

	/* Finish. */

	if ([self.delegate respondsToSelector:@selector(highlightEntrySheetOnOK:)]) {
		[self.delegate highlightEntrySheetOnOK:self];
	}
	
	[super ok:nil];
}

- (void)updateSaveButton
{
	NSString *keyword = self.matchKeywordTextField.trimmedStringValue;

	[self.okButton setEnabled:(keyword.length > 0)];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.delegate respondsToSelector:@selector(highlightEntrySheetWillClose:)]) {
		[self.delegate highlightEntrySheetWillClose:self];
	}
}

@end

#pragma mark -
#pragma mark Highlight Condition Storage.

@implementation TDCHighlightEntryMatchCondition

- (id)initWithDictionary:(NSDictionary *)dic
{
	if ((self = [super init])) {
		self.itemUUID = NSDictionaryObjectKeyValueCompare(dic, @"uniqueIdentifier", [NSString stringWithUUID]);

		self.matchKeyword = NSDictionaryObjectKeyValueCompare(dic, @"matchKeyword", NSStringEmptyPlaceholder);
		self.matchChannelID = NSDictionaryObjectKeyValueCompare(dic, @"matchChannelID", NSStringEmptyPlaceholder);

		self.matchIsExcluded = NSDictionaryBOOLKeyValueCompare(dic, @"matchIsExcluded", NO);

		return self;
	}

	return nil;
}

- (NSDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];

	[dic safeSetObject:self.itemUUID forKey:@"uniqueIdentifier"];

	[dic safeSetObject:self.matchKeyword	forKey:@"matchKeyword"];
	[dic safeSetObject:self.matchChannelID	forKey:@"matchChannelID"];

	[dic setBool:self.matchIsExcluded forKey:@"matchIsExcluded"];

	return dic;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[TDCHighlightEntryMatchCondition allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end
