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

@implementation TDCHighlightEntrySheet

- (id)init
{
	if ((self = [super init])) {
		[RZMainBundle() loadCustomNibNamed:@"TDCHighlightEntrySheet" owner:self topLevelObjects:nil];
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
	if ([self.config matchKeyword]) {
		[self.matchKeywordTextField setStringValue:[self.config matchKeyword]];
	}

	if ([self.config matchIsExcluded]) {
		[self.matchTypePopupButton selectItemWithTag:2];
	} else {
		[self.matchTypePopupButton selectItemWithTag:1];
	}

	/* Channel list. */
	IRCClient *client = [worldController() findClientById:self.clientID];

	NSInteger channelCount = 0;
	
	for (IRCChannel *channel in [client channels]) {
		NSAssertReturnLoopContinue([channel isChannel]);
		
		/* Add channels that are actual channels. */
		[self.matchChannelPopupButton addItemWithTitle:[channel name]];
		
		channelCount += 1;
		
		/* Select the channel with matching IDs. */
		if ([[channel uniqueIdentifier] isEqualToString:[self.config matchChannelID]]) {
			[self.matchChannelPopupButton selectItemWithTitle:[channel name]];
		}
	}
	
	if (client == nil || channelCount == 0) {
		/* If we have nothing, hide the menu divider under "All Channels" */
		
		[self.matchChannelPopupButton removeItemAtIndex:1];
	}
	
	/* Pop the sheet. */
	[self startSheet];

	[self.sheet makeFirstResponder:self.matchKeywordTextField];

	[self updateSaveButton];
}

- (void)ok:(id)sender
{
	/* Save keyword. */
	[self.config setMatchKeyword:[self.matchKeywordTextField stringValue]];

	/* Channel. */
	NSInteger selectedItem = [self.matchChannelPopupButton indexOfSelectedItem];

	NSString *selectedTitle = [self.matchChannelPopupButton titleOfSelectedItem];

	BOOL zeroOutChannel = YES;

	if (selectedItem > 0) { // 0 = ALL CHANNELS
		IRCClient *client = [worldController() findClientById:self.clientID];

		if (client) {
			IRCChannel *channel = [client findChannel:selectedTitle];

			if (channel) {
				zeroOutChannel = NO;
				
				[self.config setMatchChannelID:[channel uniqueIdentifier]];
			}
		}
	}

	if (zeroOutChannel) {
		[self.config setMatchChannelID:NSStringEmptyPlaceholder];
	}

	/* Entry type. */
	[self.config setMatchIsExcluded:([self.matchTypePopupButton selectedTag] == 2)];

	/* Finish. */

	if ([self.delegate respondsToSelector:@selector(highlightEntrySheetOnOK:)]) {
		[self.delegate highlightEntrySheetOnOK:self];
	}
	
	[super ok:nil];
}

- (void)updateSaveButton
{
	NSString *keyword = [self.matchKeywordTextField trimmedStringValue];

	[self.okButton setEnabled:([keyword length] > 0)];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.sheet respondsToSelector:@selector(highlightEntrySheetWillClose:)]) {
		[self.sheet highlightEntrySheetWillClose:self];
	}
}

@end

#pragma mark -
#pragma mark Highlight Condition Storage.

@implementation TDCHighlightEntryMatchCondition

- (id)initWithDictionary:(NSDictionary *)dic
{
	if ((self = [super init])) {
		self.itemUUID = [dic objectForKey:@"uniqueIdentifier" orUseDefault:[NSString stringWithUUID]];

		self.matchKeyword = [dic objectForKey:@"matchKeyword" orUseDefault:NSStringEmptyPlaceholder];
		self.matchChannelID = [dic objectForKey:@"matchChannelID" orUseDefault:NSStringEmptyPlaceholder];

		self.matchIsExcluded = [dic integerForKey:@"matchIsExcluded" orUseDefault:NO];

		return self;
	}

	return nil;
}

- (NSDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];

	[dic maybeSetObject:self.itemUUID forKey:@"uniqueIdentifier"];

	[dic maybeSetObject:self.matchKeyword	forKey:@"matchKeyword"];
	[dic maybeSetObject:self.matchChannelID	forKey:@"matchChannelID"];

	[dic setBool:self.matchIsExcluded forKey:@"matchIsExcluded"];

	return dic;
}

- (id)copyWithZone:(NSZone *)zone
{
	return [[TDCHighlightEntryMatchCondition allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end
