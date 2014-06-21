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
	if ([_config matchKeyword]) {
		[_matchKeywordTextField setStringValue:[_config matchKeyword]];
	}

	if ([_config matchIsExcluded]) {
		[_matchTypePopupButton selectItemWithTag:2];
	} else {
		[_matchTypePopupButton selectItemWithTag:1];
	}

	/* Channel list. */
	IRCClient *client = [worldController() findClientById:_clientID];

	NSInteger channelCount = 0;
	
	for (IRCChannel *channel in [client channels]) {
		NSAssertReturnLoopContinue([channel isChannel]);
		
		/* Add channels that are actual channels. */
		[_matchChannelPopupButton addItemWithTitle:[channel name]];
		
		channelCount += 1;
		
		/* Select the channel with matching IDs. */
		if ([[channel uniqueIdentifier] isEqualToString:[_config matchChannelID]]) {
			[_matchChannelPopupButton selectItemWithTitle:[channel name]];
		}
	}
	
	if (client == nil || channelCount == 0) {
		/* If we have nothing, hide the menu divider under "All Channels" */
		
		[_matchChannelPopupButton removeItemAtIndex:1];
	}
	
	/* Pop the sheet. */
	[self startSheet];

	[[self sheet] makeFirstResponder:_matchKeywordTextField];

	[self updateSaveButton];
}

- (void)ok:(id)sender
{
	/* Save keyword. */
	[_config setMatchKeyword:[_matchKeywordTextField stringValue]];

	/* Channel. */
	NSInteger selectedItem = [_matchChannelPopupButton indexOfSelectedItem];

	NSString *selectedTitle = [_matchChannelPopupButton titleOfSelectedItem];

	BOOL zeroOutChannel = YES;

	if (selectedItem > 0) { // 0 = ALL CHANNELS
		IRCClient *client = [worldController() findClientById:_clientID];

		if (client) {
			IRCChannel *channel = [client findChannel:selectedTitle];

			if (channel) {
				zeroOutChannel = NO;
				
				[_config setMatchChannelID:[channel uniqueIdentifier]];
			}
		}
	}

	if (zeroOutChannel) {
		[_config setMatchChannelID:NSStringEmptyPlaceholder];
	}

	/* Entry type. */
	_config.matchIsExcluded = ([_matchTypePopupButton selectedTag] == 2);

	/* Finish. */

	if ([[self delegate] respondsToSelector:@selector(highlightEntrySheetOnOK:)]) {
		[[self delegate] highlightEntrySheetOnOK:self];
	}
	
	[super ok:nil];
}

- (void)updateSaveButton
{
	NSString *keyword = [_matchKeywordTextField trimmedStringValue];

	[[self okButton] setEnabled:([keyword length] > 0)];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([[self delegate] respondsToSelector:@selector(highlightEntrySheetWillClose:)]) {
		[[self delegate] highlightEntrySheetWillClose:self];
	}
}

@end

#pragma mark -
#pragma mark Highlight Condition Storage.

@implementation TDCHighlightEntryMatchCondition

- (id)initWithDictionary:(NSDictionary *)dic
{
	if ((self = [super init])) {
		_itemUUID = [dic objectForKey:@"uniqueIdentifier" orUseDefault:[NSString stringWithUUID]];

		_matchKeyword = [dic objectForKey:@"matchKeyword" orUseDefault:NSStringEmptyPlaceholder];
		_matchChannelID = [dic objectForKey:@"matchChannelID" orUseDefault:NSStringEmptyPlaceholder];

		_matchIsExcluded = [dic integerForKey:@"matchIsExcluded" orUseDefault:NO];

		return self;
	}

	return nil;
}

- (NSDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];

	[dic maybeSetObject:_itemUUID forKey:@"uniqueIdentifier"];

	[dic maybeSetObject:_matchKeyword	forKey:@"matchKeyword"];
	[dic maybeSetObject:_matchChannelID	forKey:@"matchChannelID"];

	[dic setBool:_matchIsExcluded forKey:@"matchIsExcluded"];

	return dic;
}

- (id)mutableCopyWithZone:(NSZone *)zone
{
	return [[TDCHighlightEntryMatchCondition allocWithZone:zone] initWithDictionary:[self dictionaryValue]];
}

@end
