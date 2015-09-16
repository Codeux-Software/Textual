/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

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

#import "TPI_ChatFilterExtension.h"
#import "TPI_ChatFilterEditFilterSheet.h"

#define _filterListUserDefaultsKey		@"Textual Chat Filter Extension -> Filters"

@interface TPI_ChatFilterExtension ()
@property (nonatomic, strong) IBOutlet NSView *preferencesPaneView;
@property (nonatomic, weak) IBOutlet NSButton *filterAddButton;
@property (nonatomic, weak) IBOutlet NSButton *filterRemoveButton;
@property (nonatomic, weak) IBOutlet NSButton *filterEditButton;
@property (nonatomic, weak) IBOutlet NSTableView *filterTable;
@property (nonatomic, strong) IBOutlet NSArrayController *filterArrayController;
@property (nonatomic, assign) BOOL atleastOneFilterExists;
@property (nonatomic, assign) NSInteger activeChatFilterIndex;
@property (nonatomic, strong) TPI_ChatFilterEditFilterSheet *activeChatFilterEditSheet;

- (IBAction)filterTableDoubleClicked:(id)sender;

- (IBAction)filterAdd:(id)sender;
- (IBAction)filterRemove:(id)sender;
- (IBAction)filterEdit:(id)sender;
@end

@interface IRCClient (IRCClientPrivate)
- (void)setKeywordState:(IRCChannel *)t;

- (void)setUnreadState:(IRCChannel *)t;
- (void)setUnreadState:(IRCChannel *)t isHighlight:(BOOL)isHighlight;
@end

@implementation TPI_ChatFilterExtension

#pragma mark -
#pragma mark Plugin Logic

- (BOOL)receivedText:(NSString *)text authoredBy:(IRCPrefix *)textAuthor destinedFor:(NSString *)textDestination asLineType:(TVCLogLineType)lineType onClient:(IRCClient *)client receivedAt:(NSDate *)receivedAt wasEncrypted:(BOOL)wasEncrypted
{
	/* Begin processing filters */
	IRCChannel *targetChannel = nil; // This will be set later on...

	IRCUser *senderUser = nil;

	@synchronized([self.filterArrayController arrangedObjects]) {
		NSArray *arrangedObjects = [self.filterArrayController arrangedObjects];

		for (TPI_ChatFilter *filter in arrangedObjects) {
			@autoreleasepool {
				if ((lineType == TVCLogLinePrivateMessageType && [filter filterCommandPRIVMSG] == NO) ||
					(lineType == TVCLogLineActionType && [filter filterCommandPRIVMSG_ACTION] == NO) ||
					(lineType == TVCLogLineNoticeType && [filter filterCommandNOTICE] == NO))
				{
					/* Continue to next filter. This filter is not interested
					  in the line type of the input. */

					continue;
				}

				/* Try to resolve destination channel now that we 
				 know that there is a filter that will need it. */
				TPI_ChatFilterLimitToValue filterLimitedToValue = [filter filterLimitedToValue];

				if (filterLimitedToValue != TPI_ChatFilterLimitToNoLimitValue) {
					if (targetChannel == nil) {
						targetChannel = [client findChannel:textDestination];

						if (targetChannel == nil) {
							LogToConsole(@"targetChannel == nil — Returning input instead of continuing with filter");

							return YES;
						}
					}
				}

				if (filterLimitedToValue == TPI_ChatFilterLimitToChannelsValue) {
					if ([targetChannel isChannel] == NO) {
						/* Filter is limited to a channel but the destination
						 is not a channel. */

						continue;
					}
				} else if (filterLimitedToValue == TPI_ChatFilterLimitToPrivateMessagesValue) {
					if ([targetChannel isPrivateMessage] == NO) {
						/* Filter is limited to a private message but the destination
						 is not a private message. */

						continue;
					}
				} else if (filterLimitedToValue == TPI_ChatFilterLimitToSpecificItemsValue) {
					NSArray *filterLimitedToClientsIDs = [filter filterLimitedToClientsIDs];
					NSArray *filterLimitedToChannelsIDs = [filter filterLimitedToChannelsIDs];

					if ([filterLimitedToClientsIDs containsObject:[client uniqueIdentifier]] == NO &&
						[filterLimitedToChannelsIDs containsObject:[targetChannel uniqueIdentifier]] == NO)
					{
						/* Target channel is not covered by current filter. */

						continue;
					}
				}

				/* Maybe perform filter action on sender hostmask */
				NSString *filterSenderMatch = [filter filterSenderMatch];

				if (NSObjectIsEmpty(filterSenderMatch) == NO) {
					NSString *comparisonHostmask = nil;

					if ([textAuthor isServer]) {
						comparisonHostmask = [textAuthor nickname]; // Server address
					} else {
						comparisonHostmask = [textAuthor hostmask];
					}

					if ([XRRegularExpression string:comparisonHostmask isMatchedByRegex:filterSenderMatch withoutCase:YES] == NO) {
						/* If a filter specifies a sender match and the match for
						 this particular filter fails, then skip this filter. */

						continue;
					}
				}

				/* Find author in the channel */
				if ([filter filterIgnoresOperators]) {
					if ([textAuthor isServer] == NO) {
						if (senderUser == nil) {
							senderUser = [targetChannel findMember:[textAuthor nickname]];

							if (senderUser) {
								if ([senderUser isHalfOp]) {
									/* User is at least a Half-op, ignore this filter. */

									continue;
								}
							} else {
								LogToConsole(@"senderUser == nil — Skipping to next filter");

								continue;
							}
						}
					}
				}

				/* Filter text */
				if ([XRRegularExpression string:text isMatchedByRegex:[filter filterMatch] withoutCase:YES] == NO) {
					/* The input text is not matched by the filter match.
					 Continue to the next filter to try again. */

					continue;
				} else {
					if ([filter filterIgnoreContent]) {
						return NO; // Ignore original content
					}

					/* Perform actions defined by filter */
					XRPerformBlockAsynchronouslyOnMainQueue(^{
						[self performActionForFilter:filter
								 withOriginalMessage:text
										  authoredBy:textAuthor
										 destinedFor:textDestination
										  asLineType:lineType
											onClient:client];
					});

					/* Forward a copy of the message to a query? */
					NSString *filterForwardToDestination = [filter filterForwardToDestination];

					if (NSObjectIsNotEmpty(filterForwardToDestination)) {
						IRCChannel *destinationChannel = [client findChannelOrCreate:filterForwardToDestination isPrivateMessage:YES];

						NSString *fakeMessageCommand = nil;

						if (lineType == TVCLogLinePrivateMessageType ||
							lineType == TVCLogLineActionType)
						{
							fakeMessageCommand = @"PRIVMSG";
						} else if (lineType == TVCLogLineNoticeType) {
							fakeMessageCommand = @"NOTICE";
						}

						[client printToWebView:destinationChannel
										  type:lineType
									   command:fakeMessageCommand
									  nickname:[textAuthor nickname]
								   messageBody:text
								   isEncrypted:wasEncrypted
									receivedAt:receivedAt
							  referenceMessage:nil
							   completionBlock:^(BOOL isHighlight) {
								   if (lineType == TVCLogLineNoticeType) {
									   [client setUnreadState:destinationChannel];
								   } else {
									   if (isHighlight) {
										   [client setKeywordState:destinationChannel];
									   }

									   [client setUnreadState:destinationChannel isHighlight:isHighlight];
								   }
							   }];
					}

					/* Return once the first filter matches */
					return YES;
				}
			} // @autorelease
		} // for
	} // @synchronized

	return YES;
}

- (void)performActionForFilter:(TPI_ChatFilter *)filter withOriginalMessage:(NSString *)text authoredBy:(IRCPrefix *)textAuthor destinedFor:(NSString *)textDestination asLineType:(TVCLogLineType)lineType onClient:(IRCClient *)client
{
	NSString *filterActionData = [filter filterAction];

	if (NSObjectIsEmpty(filterActionData)) {
		return; // Nothing to do here...
	}

	/* Perform action */
#define _maybeReplaceValue(key, value)			if (value == nil) {																												\
													filterActionData = [filterActionData stringByReplacingOccurrencesOfString:(key) withString:NSStringEmptyPlaceholder];		\
												} else {																														\
													filterActionData = [filterActionData stringByReplacingOccurrencesOfString:(key) withString:(value)];						\
												}

	_maybeReplaceValue(@"%_channelName_%", textDestination)
	_maybeReplaceValue(@"%_localNickname_%", [client localNickname])
	_maybeReplaceValue(@"%_networkName_%", [[client supportInfo] networkName])
	_maybeReplaceValue(@"%_originalMessage_%", text)
	_maybeReplaceValue(@"%_senderAddress_%", [textAuthor address])
	_maybeReplaceValue(@"%_senderHostmask_%", [textAuthor hostmask])
	_maybeReplaceValue(@"%_senderNickname_%", [textAuthor nickname])
	_maybeReplaceValue(@"%_senderUsername_%", [textAuthor username])
	_maybeReplaceValue(@"%_serverAddress_%", [client networkAddress])

#undef _maybeReplaceValue

	NSArray *filterActions = [filterActionData split:NSStringNewlinePlaceholder];

	for (NSString *filterAction in filterActions) {
		if ([filterAction length] > 1 && [filterAction hasPrefix:@"/"] && [filterAction hasPrefix:@"//"] == NO) {
			NSString *actionCommand = [filterAction substringFromIndex:1];

			[client sendCommand:actionCommand];
		}
	}

	/* Log action to a private message */
	if ([filter filterLogMatch]) {
		IRCChannel *filterActionReportQuery = [client findChannelOrCreate:@"Filter Actions" isPrivateMessage:YES];

		NSString *formattedMessage = nil;

		if (NSObjectIsEmpty(textDestination)) {
			formattedMessage = TPILocalizedString(@"TPI_ChatFilterExtension[0002]", [filter filterTitle], [textAuthor nickname]);
		} else {
			formattedMessage = TPILocalizedString(@"TPI_ChatFilterExtension[0003]", [filter filterTitle], [textAuthor nickname], textDestination);
		}

		[client print:filterActionReportQuery type:TVCLogLinePrivateMessageType nickname:nil messageBody:formattedMessage command:TVCLogLineDefaultRawCommandValue];

		[client setUnreadState:filterActionReportQuery];
	}
}

#pragma mark -
#pragma mark Internal Filter List Storage

- (void)loadFilters
{
	NSArray *filterDictoinaries = [RZUserDefaults() arrayForKey:_filterListUserDefaultsKey];

	for (id filterObject in filterDictoinaries) {
		if ([filterObject isKindOfClass:[NSDictionary class]]) {
			TPI_ChatFilter *filter = [[TPI_ChatFilter alloc] initWithDictionary:filterObject];

			[self.filterArrayController addObject:filter];
		}
	}

	[self reloadFilterCount];
}

- (void)saveFilters
{
	NSArray *arrangedObjects = [self.filterArrayController arrangedObjects];

	NSMutableArray *filterDictionaries = [NSMutableArray arrayWithCapacity:[arrangedObjects count]];

	for (TPI_ChatFilter *filter in arrangedObjects) {
		[filterDictionaries addObject:[filter dictionaryValue]];
	}

	[RZUserDefaults() setObject:[filterDictionaries copy] forKey:_filterListUserDefaultsKey];

	[self reloadFilterCount];
}

- (void)reloadFilterCount
{
	NSArray *arrangedObjects = [self.filterArrayController arrangedObjects];

	self.atleastOneFilterExists = ([arrangedObjects count] > 0);
}

#pragma mark -
#pragma mark Preference Pane

- (void)pluginLoadedIntoMemory
{
	if ([TPIBundleFromClass() loadNibNamed:@"TPI_ChatFilterExtension" owner:self topLevelObjects:nil] == NO) {
		NSAssert(NO, @"Failed to load interface");
	}

	self.activeChatFilterIndex = -1;

	self.atleastOneFilterExists = NO;

	[self loadFilters];
}

- (NSView *)pluginPreferencesPaneView
{
	return self.preferencesPaneView;
}

- (NSString *)pluginPreferencesPaneMenuItemName
{
	return TPILocalizedString(@"TPI_ChatFilterExtension[0001]");
}

- (void)filterTableDoubleClicked:(id)sender
{
	[self filterEdit:sender];
}

- (void)filterAdd:(id)sender
{
	[self editFilter:nil];
}

- (void)filterRemove:(id)sender
{
	NSInteger selectedIndex = [self.filterArrayController selectionIndex];

	[self.filterArrayController removeObjectAtArrangedObjectIndex:selectedIndex];

	[self saveFilters];
}

- (void)filterEdit:(id)sender
{
	NSInteger selectedIndex = [self.filterArrayController selectionIndex];

	if (selectedIndex >= 0) {
		TPI_ChatFilter *filter = [self.filterArrayController arrangedObjects][selectedIndex];

		[self editFilter:filter atIndex:selectedIndex];
	}
}

- (void)editFilter:(id)filter
{
	[self editFilter:filter atIndex:(-1)];
}

- (void)editFilter:(id)filter atIndex:(NSInteger)filterIndex
{
	self.activeChatFilterIndex = filterIndex;

	 self.activeChatFilterEditSheet = [TPI_ChatFilterEditFilterSheet new];

	[self.activeChatFilterEditSheet setWindow:[NSApp keyWindow]];

	[self.activeChatFilterEditSheet setDelegate:self];

	[self.activeChatFilterEditSheet startWithFilter:filter];
}

- (void)chatFilterEditFilterSheetWillClose:(TPI_ChatFilterEditFilterSheet *)sender
{
	XRPerformBlockAsynchronouslyOnMainQueue(^{
		self.activeChatFilterIndex = -1;

		self.activeChatFilterEditSheet = nil;
	});
}

- (void)chatFilterEditFilterSheet:(TPI_ChatFilterEditFilterSheet *)sender onOK:(TPI_ChatFilter *)filter
{
	XRPerformBlockAsynchronouslyOnMainQueue(^{
		TPI_ChatFilter *newFilter = [filter copy];

		if (self.activeChatFilterIndex < 0) {
			[self.filterArrayController addObject:newFilter];
		} else {
			[self.filterArrayController removeObjectAtArrangedObjectIndex:self.activeChatFilterIndex];

			[self.filterArrayController insertObject:newFilter atArrangedObjectIndex:self.activeChatFilterIndex];
		}

		[self saveFilters];
	});
}

@end
