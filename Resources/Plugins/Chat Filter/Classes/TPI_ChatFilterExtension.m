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

#define _filterTableDragToken			@"filterTableDragToken"

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

@implementation TPI_ChatFilterExtension

#pragma mark -
#pragma mark Plugin Logic

- (BOOL)testFilterDestination:(TPI_ChatFilter *)filter againstText:(NSString *)text authoredBy:(IRCPrefix *)textAuthor destinedFor:(IRCChannel *)textDestination onClient:(IRCClient *)client
{
	/* Try to resolve destination channel now that we
	 know that there is a filter that will need it. */
	TPI_ChatFilterLimitToValue filterLimitedToValue = [filter filterLimitedToValue];

	if (filterLimitedToValue != TPI_ChatFilterLimitToNoLimitValue || [filter filterIgnoresOperators]) {
		if (textDestination == nil && [textAuthor isServer] == NO) {
			LogToConsoleDebug("textDestination == nil — Returning input instead of continuing with filter");

			return NO;
		}
	}

	if (filterLimitedToValue == TPI_ChatFilterLimitToChannelsValue) {
		if ([textDestination isChannel] == NO) {
			/* Filter is limited to a channel but the destination
			 is not a channel. */

			return NO;
		}
	} else if (filterLimitedToValue == TPI_ChatFilterLimitToPrivateMessagesValue) {
		if ([textDestination isPrivateMessage] == NO) {
			/* Filter is limited to a private message but the destination
			 is not a private message. */

			return NO;
		}
	} else if (filterLimitedToValue == TPI_ChatFilterLimitToSpecificItemsValue) {
		NSArray *filterLimitedToClientsIDs = [filter filterLimitedToClientsIDs];
		NSArray *filterLimitedToChannelsIDs = [filter filterLimitedToChannelsIDs];

		if ([filterLimitedToClientsIDs containsObject:[client uniqueIdentifier]] == NO &&
			[filterLimitedToChannelsIDs containsObject:[textDestination uniqueIdentifier]] == NO)
		{
			/* Target channel is not covered by current filter. */

			return NO;
		}
	}

	return YES;
}

- (BOOL)testFilterSender:(TPI_ChatFilter *)filter authoredBy:(IRCPrefix *)textAuthor onClient:(IRCClient *)client
{
	/* Check whether the sender is the local user */
	if ([filter filterLimitedToMyself]) {
		NSString *comparisonValue1 = [client userNickname];

		NSString *comparisonValue2 = [textAuthor nickname];

		if ([comparisonValue1 isEqualIgnoringCase:comparisonValue2] == NO) {
			return NO;
		} else {
			return YES;
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

			return NO;
		}
	}

	return YES;
}

- (BOOL)testFilterMatch:(TPI_ChatFilter *)filter againstText:(NSString *)text allowingEmptyText:(BOOL)allowingEmptyText
{
	/* Filter text */
	if (text == nil) {
		if (allowingEmptyText) {
			return YES;
		} else {
			return NO;
		}
	}

	NSString *filterMatch = [filter filterMatch];

	if (NSObjectIsEmpty(filterMatch) == NO) {
		if ([XRRegularExpression string:text isMatchedByRegex:filterMatch withoutCase:YES] == NO) {
			/* The input text is not matched by the filter match.
			 Continue to the next filter to try again. */

			return NO;
		}
	}

	return YES;
}

- (BOOL)receivedCommand:(NSString *)command withText:(NSString *)text authoredBy:(IRCPrefix *)textAuthor destinedFor:(IRCChannel *)textDestination onClient:(IRCClient *)client receivedAt:(NSDate *)receivedAt
{
	/* Begin processing filters */
	@synchronized([self.filterArrayController arrangedObjects]) {
		NSArray *arrangedObjects = [self.filterArrayController arrangedObjects];

		for (TPI_ChatFilter *filter in arrangedObjects) {
			@autoreleasepool {
#define _commandMatchesEvent(_command_, _event_)		([command isEqualToString:(_command_)] && [filter isEventTypeEnabled:(_event_)] == NO)

				if ((_commandMatchesEvent(@"JOIN", TPI_ChatFilterUserJoinedChannelEventType) ||
					 _commandMatchesEvent(@"PART", TPI_ChatFilterUserLeftChannelEventType) ||
					 _commandMatchesEvent(@"KICK", TPI_ChatFilterUserKickedFromChannelEventType) ||
					 _commandMatchesEvent(@"QUIT", TPI_ChatFilterUserDisconnectedEventType) ||
					 _commandMatchesEvent(@"NICK", TPI_ChatFilterUserChangedNicknameEventType) ||
					 _commandMatchesEvent(@"TOPIC", TPI_ChatFilterChannelTopicChangedEventType) ||
					 _commandMatchesEvent(@"MODE", TPI_ChatFilterChannelModeChangedEventType) ||
					 _commandMatchesEvent(@"332", TPI_ChatFilterChannelTopicReceivedEventType) ||
					 _commandMatchesEvent(@"324", TPI_ChatFilterChannelModeReceivedEventType)) &&
					[[filter filterEventsNumerics] containsObject:command] == NO)
				{
					/* Continue to next filter. This filter is not interested
					 in the line type of the input. */

					continue;
				}

#undef _commandMatchesEvent

				/* Perform common filter checks */
				if ([self testFilterDestination:filter againstText:text authoredBy:textAuthor destinedFor:textDestination onClient:client] == NO) {
					continue;
				}

				if ([self testFilterSender:filter authoredBy:textAuthor onClient:client] == NO) {
					continue;
				}

				if ([self testFilterMatch:filter againstText:text allowingEmptyText:YES] == NO) {
					continue;
				}

				/* Perform actions defined by filter */
				XRPerformBlockAsynchronouslyOnMainQueue(^{
					[self performActionForFilter:filter
							 withOriginalMessage:text
									  authoredBy:textAuthor
									 destinedFor:textDestination
										onClient:client];
				});

				if ([filter filterIgnoreContent]) {
					return NO; // Ignore original content
				}

				/* Return once the first filter matches */
				return YES;
			} // @autorelease
		} // for
	} // @synchronized

	return YES;
}

- (BOOL)receivedText:(NSString *)text authoredBy:(IRCPrefix *)textAuthor destinedFor:(IRCChannel *)textDestination asLineType:(TVCLogLineType)lineType onClient:(IRCClient *)client receivedAt:(NSDate *)receivedAt wasEncrypted:(BOOL)wasEncrypted
{
	/* Begin processing filters */
	/* Finding the IRCUser instance for the sender has a lot of overhead involved
	 which means it is easier to store it in a variable here and find only once. */
	IRCUser *senderUser = nil;

	@synchronized([self.filterArrayController arrangedObjects]) {
		NSArray *arrangedObjects = [self.filterArrayController arrangedObjects];

		for (TPI_ChatFilter *filter in arrangedObjects) {
			@autoreleasepool {
				if (((lineType == TVCLogLinePrivateMessageType || lineType == TVCLogLinePrivateMessageNoHighlightType) &&
					 [filter isEventTypeEnabled:TPI_ChatFilterPlainTextMessageEventType] == NO) ||

					((lineType == TVCLogLineActionType || lineType == TVCLogLineActionNoHighlightType)
					 && [filter isEventTypeEnabled:TPI_ChatFilterActionMessageEventType] == NO) ||

					(lineType == TVCLogLineNoticeType && [filter isEventTypeEnabled:TPI_ChatFilterNoticeMessageEventType] == NO))
				{
					/* Continue to next filter. This filter is not interested
					  in the line type of the input. */

					continue;
				}

				/* Perform common filter checks */
				if ([self testFilterDestination:filter againstText:text authoredBy:textAuthor destinedFor:textDestination onClient:client] == NO) {
					continue;
				}

				if ([self testFilterSender:filter authoredBy:textAuthor onClient:client] == NO) {
					continue;
				}

				if ([filter filterIgnoresOperators] && [textDestination isChannel]) {
					if ([textAuthor isServer] == NO) {
						if (senderUser == nil) {
							senderUser = [textDestination findMember:[textAuthor nickname]];

							if (senderUser) {
								if ([senderUser isHalfOp]) {
									/* User is at least a Half-op, ignore this filter. */

									continue;
								}
							} else {
								LogToConsoleDebug("senderUser == nil — Skipping to next filter")
								
								continue;
							}
						}
					}
				}

				if ([self testFilterMatch:filter againstText:text allowingEmptyText:NO] == NO) {
					continue;
				}

				/* Perform actions defined by filter */
				XRPerformBlockAsynchronouslyOnMainQueue(^{
					[self performActionForFilter:filter
							 withOriginalMessage:text
									  authoredBy:textAuthor
									 destinedFor:textDestination
										onClient:client];
				});

				/* Forward a copy of the message to a query? */
				NSString *filterForwardToDestination = [filter filterForwardToDestination];

				if (NSObjectIsNotEmpty(filterForwardToDestination)) {
					IRCChannel *destinationChannel = [client findChannelOrCreate:filterForwardToDestination isPrivateMessage:YES];

					NSString *fakeMessageCommand = nil;

					if (lineType == TVCLogLinePrivateMessageType ||
						lineType == TVCLogLinePrivateMessageNoHighlightType ||
						lineType == TVCLogLineActionType ||
						lineType == TVCLogLineActionNoHighlightType)
					{
						fakeMessageCommand = @"PRIVMSG";
					} else if (lineType == TVCLogLineNoticeType) {
						fakeMessageCommand = @"NOTICE";
					}

					[client print:text
							   by:textAuthor.nickname
						inChannel:destinationChannel
						   asType:lineType
						  command:fakeMessageCommand
					   receivedAt:receivedAt
					  isEncrypted:wasEncrypted
				 referenceMessage:nil
					 completionBlock:^(TVCLogControllerPrintOperationContext *context) {
						 BOOL isHighlight = [context isHighlight];

						 if (lineType != TVCLogLineNoticeType) {
							 [client setUnreadStateForChannel:destinationChannel];
						 } else {
							 if (isHighlight) {
								 [client setHighlightStateForChannel:destinationChannel];
							 }

							 [client setUnreadStateForChannel:destinationChannel isHighlight:isHighlight];
							 [client setUnreadStateForChannel:destinationChannel isHighlight:isHighlight];
						 }
					 }];
				}

				if ([filter filterIgnoreContent]) {
					return NO; // Ignore original content
				}

				/* Return once the first filter matches */
				return YES;
			} // @autorelease
		} // for
	} // @synchronized

	return YES;
}

- (void)performActionForFilter:(TPI_ChatFilter *)filter withOriginalMessage:(NSString *)text authoredBy:(IRCPrefix *)textAuthor destinedFor:(IRCChannel *)textDestination onClient:(IRCClient *)client
{
	NSString *filterActionData = [filter filterAction];

	if (NSObjectIsEmpty(filterActionData)) {
		return; // Nothing to do here...
	}

	/* Perform action */
	NSString *eventText = text;

	if (eventText == nil) {
		eventText = NSStringEmptyPlaceholder;
	}

#define _maybeReplaceValue(key, value)			if (value == nil) {																												\
													filterActionData = [filterActionData stringByReplacingOccurrencesOfString:(key) withString:NSStringEmptyPlaceholder];		\
												} else {																														\
													filterActionData = [filterActionData stringByReplacingOccurrencesOfString:(key) withString:(value)];						\
												}

	_maybeReplaceValue(@"%_channelName_%", [textDestination name])
	_maybeReplaceValue(@"%_localNickname_%", [client userNickname])
	_maybeReplaceValue(@"%_networkName_%", [[client supportInfo] networkName])
	_maybeReplaceValue(@"%_originalMessage_%", text)
	_maybeReplaceValue(@"%_senderAddress_%", [textAuthor address])
	_maybeReplaceValue(@"%_senderHostmask_%", [textAuthor hostmask])
	_maybeReplaceValue(@"%_senderNickname_%", [textAuthor nickname])
	_maybeReplaceValue(@"%_senderUsername_%", [textAuthor username])
	_maybeReplaceValue(@"%_serverAddress_%", [client serverAddress])

#undef _maybeReplaceValue

	NSArray *filterActions = [filterActionData componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

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

		if (textDestination == nil) {
			formattedMessage = TPILocalizedString(@"TPI_ChatFilterExtension[0002]", [filter filterTitle], [textAuthor nickname]);
		} else {
			formattedMessage = TPILocalizedString(@"TPI_ChatFilterExtension[0003]", [filter filterTitle], [textAuthor nickname], [textDestination name]);
		}

		[client print:formattedMessage
				   by:nil
			inChannel:filterActionReportQuery
			   asType:TVCLogLinePrivateMessageType
			  command:IRCPrivateCommandIndex("privmsg")];

		[client setUnreadStateForChannel:filterActionReportQuery];
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
	[self performBlockOnMainThread:^{
		if ([TPIBundleFromClass() loadNibNamed:@"TPI_ChatFilterExtension" owner:self topLevelObjects:nil] == NO) {
			NSAssert(NO, @"Failed to load interface");
		}
	}];

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

- (void)awakeFromNib
{
	[self.filterTable registerForDraggedTypes:@[_filterTableDragToken]];
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
	BOOL performRemove = [TLOPopupPrompts dialogWindowWithMessage:TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0010][2]")
															title:TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0010][1]")
													defaultButton:TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0010][3]")
												  alternateButton:TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0010][4]")];

	if (performRemove == NO) {
		return;
	}

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

#pragma mark -
#pragma mark Table View Delegate

- (BOOL)tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pasteboard
{
	NSData *data = [NSKeyedArchiver archivedDataWithRootObject:rowIndexes];

	[pasteboard declareTypes:@[_filterTableDragToken] owner:self.filterArrayController];

	[pasteboard setData:data forType:_filterTableDragToken];

	return YES;
}

- (NSDragOperation)tableView:(NSTableView *)tableView validateDrop:(id<NSDraggingInfo>)info proposedRow:(NSInteger)row proposedDropOperation:(NSTableViewDropOperation)dropOperation
{
	return NSDragOperationGeneric;
}

- (BOOL)tableView:(NSTableView *)tableView acceptDrop:(id<NSDraggingInfo>)info row:(NSInteger)dropRow dropOperation:(NSTableViewDropOperation)dropOperation
{
	NSPasteboard *pasteboard = [info draggingPasteboard];

	NSData *rowData = [pasteboard dataForType:_filterTableDragToken];

	NSIndexSet *rowIndexes = [NSKeyedUnarchiver unarchiveObjectWithData:rowData];

	NSInteger filterIndex = [rowIndexes firstIndex];

	TPI_ChatFilter *draggedFilter = [self.filterArrayController arrangedObjects][filterIndex];

	[self.filterArrayController insertObject:draggedFilter atArrangedObjectIndex:dropRow];

	if (filterIndex > dropRow) {
		[self.filterArrayController removeObjectAtArrangedObjectIndex:(filterIndex + 1)];
	} else {
		[self.filterArrayController removeObjectAtArrangedObjectIndex:filterIndex];
	}

	[self saveFilters];

	return YES;
}

@end
