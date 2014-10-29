/* ********************************************************************* 
				  _____         _               _
				 |_   _|____  _| |_ _   _  __ _| |
				   | |/ _ \ \/ / __| | | |/ _` | |
				   | |  __/>  <| |_| |_| | (_| | |
				   |_|\___/_/\_\\__|\__,_|\__,_|_|

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
    * Neither the name of Textual and/or Codeux Software, nor the names of 
      its contributors may be used to endorse or promote products derived 
      from this software without specific prior written permission.

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

- (instancetype)init
{
	if ((self = [super init])) {
		[RZMainBundle() loadCustomNibNamed:@"TDCHighlightEntrySheet" owner:self topLevelObjects:nil];
	
		[self.matchKeywordTextField setOnlyShowStatusIfErrorOccurs:YES];
		[self.matchKeywordTextField setStringValueUsesOnlyFirstToken:NO];
		[self.matchKeywordTextField setStringValueIsInvalidOnEmpty:YES];
		[self.matchKeywordTextField setStringValueIsTrimmed:YES];
		
		[self.matchKeywordTextField setTextDidChangeCallback:self];
	}

	return self;
}

- (void)startWithChannels:(NSArray *)channels
{
	/* Start populating. */
	self.channelList = channels;
	
	if ([self.config matchKeyword]) {
		[self.matchKeywordTextField setStringValue:[self.config matchKeyword]];
	}

	if ([self.config matchIsExcluded]) {
		[self.matchTypePopupButton selectItemWithTag:2];
	} else {
		[self.matchTypePopupButton selectItemWithTag:1];
	}

	/* Channel list. */
	NSInteger channelCount = 0;
	
	for (IRCChannelConfig *channel in self.channelList) {
		/* Add channels that are actual channels. */
		[self.matchChannelPopupButton addItemWithTitle:[channel channelName]];
		
		channelCount += 1;
		
		/* Select the channel with matching IDs. */
		if ([[channel itemUUID] isEqualToString:[self.config matchChannelID]]) {
			[self.matchChannelPopupButton selectItemWithTitle:[channel channelName]];
		}
	}
	
	if (channelCount == 0) {
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
	[self.config setMatchKeyword:[self.matchKeywordTextField value]];

	/* Channel. */
	NSInteger selectedItem = [self.matchChannelPopupButton indexOfSelectedItem];

	NSString *selectedTitle = [self.matchChannelPopupButton titleOfSelectedItem];

	BOOL zeroOutChannel = YES;

	if (selectedItem > 0) { // 0 = ALL CHANNELS
		IRCChannelConfig *channel = nil;
		
		for (IRCChannelConfig *c in self.channelList) {
			if ([[c channelName] isEqualToString:selectedTitle]) {
				channel = c;
			}
		}
		
		if (channel) {
			zeroOutChannel = NO;
			
			[self.config setMatchChannelID:[channel itemUUID]];
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

- (void)validatedTextFieldTextDidChange:(id)sender
{
	[self updateSaveButton];
}

- (void)updateSaveButton
{
	[self.okButton setEnabled:[self.matchKeywordTextField valueIsValid]];
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

- (instancetype)initWithDictionary:(NSDictionary *)dic
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
