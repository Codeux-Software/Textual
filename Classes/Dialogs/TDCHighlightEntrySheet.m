/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

@interface TDCHighlightEntrySheet ()
@property (nonatomic, copy) NSArray *channelList;
@property (nonatomic, nweak) IBOutlet TVCTextFieldWithValueValidation *matchKeywordTextField;
@property (nonatomic, nweak) IBOutlet NSPopUpButton *matchTypePopupButton;
@property (nonatomic, nweak) IBOutlet NSPopUpButton *matchChannelPopupButton;
@end

@implementation TDCHighlightEntrySheet

- (instancetype)init
{
	if ((self = [super init])) {
		[RZMainBundle() loadNibNamed:@"TDCHighlightEntrySheet" owner:self topLevelObjects:nil];
	
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
	self.channelList = channels;

	[self.matchKeywordTextField setStringValue:[self.config matchKeyword]];

	if ([self.config matchIsExcluded]) {
		[self.matchTypePopupButton selectItemWithTag:2];
	} else {
		[self.matchTypePopupButton selectItemWithTag:1];
	}

	NSInteger channelCount = 0;
	
	for (IRCChannelConfig *channel in self.channelList) {
		[self.matchChannelPopupButton addItemWithTitle:[channel channelName]];

		if (NSObjectsAreEqual([channel itemUUID], [self.config matchChannelID])) {
			[self.matchChannelPopupButton selectItemWithTitle:[channel channelName]];
		}

		channelCount += 1;
	}

	if (channelCount == 0) {
		[self.matchChannelPopupButton removeItemAtIndex:1];
	}

	[self startSheet];
	[self updateSaveButton];

	[self.sheet makeFirstResponder:self.matchKeywordTextField];
}

- (void)ok:(id)sender
{
	NSInteger selectedChannelItem = [self.matchChannelPopupButton indexOfSelectedItem];

	NSString *selectedChannelTitle = [self.matchChannelPopupButton titleOfSelectedItem];

	if (selectedChannelItem == 0) { // 0 = ALL CHANNELS
		[self.config setMatchChannelID:nil];
	} else {
		IRCChannelConfig *channel = nil;
		
		for (IRCChannelConfig *c in self.channelList) {
			if ([[c channelName] isEqualToString:selectedChannelTitle]) {
				channel = c;
			}
		}
		
		if (channel) {
			[self.config setMatchChannelID:[channel itemUUID]];
		} else {
			[self.config setMatchChannelID:nil];
		}
	}

	[self.config setMatchIsExcluded:([self.matchTypePopupButton selectedTag] == 2)];

	[self.config setMatchKeyword:[self.matchKeywordTextField value]];

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
		self.itemUUID = [NSString stringWithUUID];

		[self populateDictionaryValues:dic];
	}

	return self;
}

- (void)populateDictionaryValues:(NSDictionary *)dic
{
	[dic assignStringTo:&_itemUUID forKey:@"uniqueIdentifier"];

	[dic assignStringTo:&_matchKeyword forKey:@"matchKeyword"];
	[dic assignStringTo:&_matchChannelID forKey:@"matchChannelID"];

	[dic assignBoolTo:&_matchIsExcluded forKey:@"matchIsExcluded"];
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
