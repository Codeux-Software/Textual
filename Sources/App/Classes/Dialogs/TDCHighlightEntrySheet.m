/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 * Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "NSObjectHelperPrivate.h"
#import "IRCChannelConfig.h"
#import "IRCHighlightMatchCondition.h"
#import "TVCValidatedTextField.h"
#import "TDCHighlightEntrySheetPrivate.h"

NS_ASSUME_NONNULL_BEGIN

@interface TDCHighlightEntrySheet ()
@property (nonatomic, strong) IRCHighlightMatchConditionMutable *config;
@property (nonatomic, copy) NSArray<IRCChannelConfig *> *channelList;
@property (nonatomic, weak) IBOutlet TVCValidatedTextField *matchKeywordTextField;
@property (nonatomic, weak) IBOutlet NSPopUpButton *matchTypePopupButton;
@property (nonatomic, weak) IBOutlet NSPopUpButton *matchChannelPopupButton;
@end

@implementation TDCHighlightEntrySheet

ClassWithDesignatedInitializerInitMethod

- (instancetype)initWithConfig:(nullable IRCHighlightMatchCondition *)config
{
	if ((self = [super init])) {
		if (config) {
			self.config = [config mutableCopy];
		} else {
			self.config = [IRCHighlightMatchConditionMutable new];
		}

		[self prepareInitialState];

		[self loadConfig];

		return self;
	}

	return nil;
}

- (void)prepareInitialState
{
	[RZMainBundle() loadNibNamed:@"TDCHighlightEntrySheet" owner:self topLevelObjects:nil];

	self.matchKeywordTextField.stringValueUsesOnlyFirstToken = NO;
	self.matchKeywordTextField.stringValueIsInvalidOnEmpty = YES;
	self.matchKeywordTextField.stringValueIsTrimmed = YES;

	self.matchKeywordTextField.textDidChangeCallback = self;
}

- (void)loadConfig
{
	self.matchKeywordTextField.stringValue = self.config.matchKeyword;

	if (self.config.matchIsExcluded == NO) {
		[self.matchTypePopupButton selectItemWithTag:1];
	} else {
		[self.matchTypePopupButton selectItemWithTag:2];
	}
}

- (void)startWithChannels:(NSArray<IRCChannelConfig *> *)channels
{
	NSParameterAssert(channels != nil);

	self.channelList = channels;

	NSString *matchChannelId = self.config.matchChannelId;

	NSUInteger channelCount = 0;

	for (IRCChannelConfig *channel in self.channelList) {
		NSString *channelName = channel.channelName;

		[self.matchChannelPopupButton addItemWithTitle:channelName];

		if ([channel.uniqueIdentifier isEqualToString:matchChannelId]) {
			[self.matchChannelPopupButton selectItemWithTitle:channelName];
		}

		channelCount += 1;
	}

	if (channelCount == 0) {
		[self.matchChannelPopupButton removeItemAtIndex:1];
	}

	[self startSheet];

	[self.sheet makeFirstResponder:self.matchKeywordTextField];
}

- (void)ok:(id)sender
{
	if ([self okOrError] == NO) {
		return;
	}

	self.config.matchIsExcluded = (self.matchTypePopupButton.selectedTag == 2);

	self.config.matchKeyword = self.matchKeywordTextField.value;

	NSInteger selectedChannelIndex = self.matchChannelPopupButton.indexOfSelectedItem;

	if (selectedChannelIndex > 0) {
		NSString *selectedChannelName = self.matchChannelPopupButton.titleOfSelectedItem;

		for (IRCChannelConfig *c in self.channelList) {
			if ([c.channelName isEqualToString:selectedChannelName]) {
				self.config.matchChannelId = c.uniqueIdentifier;

				break;
			}
		}
	}

	[self.delegate highlightEntrySheet:self onOk:[self.config copy]];

	[super ok:sender];
}

- (BOOL)okOrError
{
	return [self okOrErrorForTextField:self.matchKeywordTextField];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	[self.delegate highlightEntrySheetWillClose:self];
}

@end

NS_ASSUME_NONNULL_END
