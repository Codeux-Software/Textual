/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2015 - 2018 Codeux Software, LLC & respective contributors.
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

#import "TPI_ChatFilterLogic.h"

#import "IRCClientPrivate.h"

NS_ASSUME_NONNULL_BEGIN

@interface TPI_ChatFilterLogic ()
@property (nonatomic, weak) TPI_ChatFilterExtension *parentObject;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSNumber *> *filterActionLastPerforms;
@end

@implementation TPI_ChatFilterLogic

- (instancetype)initWithParentObject:(TPI_ChatFilterExtension *)parentObject
{
	NSParameterAssert(parentObject != nil);

	if ((self = [super init])) {
		self.parentObject = parentObject;

		[self prepareInitialState];

		return self;
	}

	return nil;
}

- (void)prepareInitialState
{
	self.filterActionLastPerforms = [NSMutableDictionary dictionary];
}

- (BOOL)testFilterDestination:(TPI_ChatFilter *)filter authoredBy:(IRCPrefix *)textAuthor destinedFor:(nullable IRCChannel *)textDestination onClient:(IRCClient *)client
{
	/* Try to resolve destination channel now that we
	 know that there is a filter that will need it. */
	TPI_ChatFilterLimitToValue filterLimitedToValue = filter.filterLimitedToValue;

	if (filterLimitedToValue != TPI_ChatFilterLimitToValueNoLimit || filter.filterIgnoreOperators) {
		if (textDestination == nil && textAuthor.isServer == NO) {
			LogToConsoleDebug("textDestination == nil — Returning input instead of continuing with filter");

			return NO;
		}
	}

	if (filterLimitedToValue == TPI_ChatFilterLimitToValueChannels) {
		if (textDestination.isChannel == NO) {
			/* Filter is limited to a channel but the destination
			 is not a channel. */

			return NO;
		}
	} else if (filterLimitedToValue == TPI_ChatFilterLimitToValuePrivateMessages) {
		if (textDestination.isPrivateMessage == NO) {
			/* Filter is limited to a private message but the destination
			 is not a private message. */

			return NO;
		}
	} else if (filterLimitedToValue == TPI_ChatFilterLimitToValueSpecificItems) {
		NSArray *filterLimitedToClientsIDs = filter.filterLimitedToClientsIDs;
		NSArray *filterLimitedToChannelsIDs = filter.filterLimitedToChannelsIDs;

		if ([filterLimitedToClientsIDs containsObject:client.uniqueIdentifier] == NO &&
			[filterLimitedToChannelsIDs containsObject:textDestination.uniqueIdentifier] == NO)
		{
			/* Target channel is not covered by current filter. */

			return NO;
		}
	}

	return YES;
}

- (BOOL)testFilterSender:(TPI_ChatFilter *)filter authoredBy:(IRCPrefix *)textAuthor onClient:(IRCClient *)client
{
	/* Check whether the sender is mysql */
	if (filter.filterLimitedToMyself) {
		NSString *comparisonValue1 = client.userNickname;

		NSString *comparisonValue2 = textAuthor.nickname;

		if ([comparisonValue1 isEqualToStringIgnoringCase:comparisonValue2] == NO) {
			return NO;
		}

		return YES;
	}

	/* Maybe perform filter action on sender hostmask */
	NSString *filterSenderMatch = filter.filterSenderMatch;

	if (filterSenderMatch.length > 0) {
		NSString *comparisonHostmask = nil;

		if (textAuthor.isServer) {
			comparisonHostmask = textAuthor.nickname; // Server address
		} else {
			comparisonHostmask = textAuthor.hostmask;
		}

		if ([XRRegularExpression string:comparisonHostmask isMatchedByRegex:filterSenderMatch withoutCase:YES] == NO) {
			/* If a filter specifies a sender match and the match for
			 this particular filter fails, then skip this filter. */

			return NO;
		}
	}

	return YES;
}

- (BOOL)testFilterMatch:(TPI_ChatFilter *)filter againstText:(nullable NSString *)text allowingNilText:(BOOL)allowingNilText
{
	/* Filter text */
	if (text == nil) {
		if (allowingNilText) {
			return YES;
		} else {
			return NO;
		}
	}

	NSString *filterMatch = filter.filterMatch;

	if (filterMatch.length > 0) {
		if ([TPCPreferences removeAllFormatting] == NO) {
			text = text.stripIRCEffects;
		}

		if ([XRRegularExpression string:text isMatchedByRegex:filterMatch withoutCase:YES] == NO) {
			/* The input text is not matched by the filter match.
			 Continue to the next filter to try again. */

			return NO;
		}
	}

	return YES;
}

- (BOOL)receivedCommand:(NSString *)command withText:(nullable NSString *)text authoredBy:(IRCPrefix *)textAuthor destinedFor:(nullable IRCChannel *)textDestination onClient:(IRCClient *)client receivedAt:(NSDate *)receivedAt referenceMessage:(nullable IRCMessage *)referenceMessage
{
	/* Begin processing filters */
	NSArray *filters = self.parentObject.filterArrayController.content;

	for (TPI_ChatFilter *filter in filters) {
		@autoreleasepool {
			if ([filter isCommandEnabled:command] == NO) {
				/* Continue to next filter. This filter is not interested
				 in the line type of the input. */

				continue;
			}

			/* Perform common filter checks */
			if ([self testFilterDestination:filter authoredBy:textAuthor destinedFor:textDestination onClient:client] == NO) {
				continue;
			}

			if ([self testFilterSender:filter authoredBy:textAuthor onClient:client] == NO) {
				continue;
			}

			if ([self testFilterMatch:filter againstText:text allowingNilText:YES] == NO) {
				continue;
			}

			/* Perform actions defined by filter */
			XRPerformBlockAsynchronouslyOnMainQueue(^{
				[self performActionForFilter:filter
						 withOriginalMessage:text
								  authoredBy:textAuthor
								 destinedFor:textDestination
									onClient:client
							referenceMessage:referenceMessage];
			});

			/* Forward a copy of the message to a query? */
			NSString *filterForwardToDestination = filter.filterForwardToDestination;

			if (filterForwardToDestination.length > 0 && text.length > 0) {
				IRCChannel *destinationChannel = [client findChannelOrCreate:filterForwardToDestination isPrivateMessage:YES];

				NSString *message = TPILocalizedString(@"TPI_ChatFilterLogic[dct-7h]", command, text);

				[client print:message
						   by:nil
					inChannel:destinationChannel
					   asType:TVCLogLineTypeDebug
					  command:TVCLogLineDefaultCommandValue
				   receivedAt:receivedAt
				  isEncrypted:NO
			 referenceMessage:nil
				 completionBlock:^(TVCLogControllerPrintOperationContext *context) {
					 [client setUnreadStateForChannel:destinationChannel];
				 }];
			}

			if (filter.filterIgnoreContent) {
				return NO; // Ignore original content
			}

			/* Return once the first filter matches */
			return YES;
		} // @autorelease
	} // for

	return YES;
}

- (BOOL)receivedText:(NSString *)text authoredBy:(IRCPrefix *)textAuthor destinedFor:(nullable IRCChannel *)textDestination asLineType:(TVCLogLineType)lineType onClient:(IRCClient *)client receivedAt:(NSDate *)receivedAt wasEncrypted:(BOOL)wasEncrypted
{
	/* Begin processing filters */
	/* Finding the IRCUser instance for the sender has a lot of overhead involved
	 which means it is easier to store it in a variable here and find only once. */
	/* This only works because textDestination is same for each filter check. */
	IRCChannelUser *senderUser = nil;

	NSArray *filters = self.parentObject.filterArrayController.content;

	for (TPI_ChatFilter *filter in filters) {
		@autoreleasepool {
			if (((lineType == TVCLogLineTypePrivateMessage || lineType == TVCLogLineTypePrivateMessageNoHighlight) &&
				 [filter isEventTypeEnabled:TPI_ChatFilterEventTypePlainTextMessage] == NO) ||

				((lineType == TVCLogLineTypeAction || lineType == TVCLogLineTypeActionNoHighlight) &&
				 [filter isEventTypeEnabled:TPI_ChatFilterEventTypeActionMessage] == NO) ||

				(lineType == TVCLogLineTypeNotice &&
				 [filter isEventTypeEnabled:TPI_ChatFilterEventTypeNoticeMessage] == NO))
			{
				/* Continue to next filter. This filter is not interested
				 in the line type of the input. */

				continue;
			}

			/* Perform common filter checks */
			if ([self testFilterDestination:filter authoredBy:textAuthor destinedFor:textDestination onClient:client] == NO) {
				continue;
			}

			if ([self testFilterSender:filter authoredBy:textAuthor onClient:client] == NO) {
				continue;
			}

			if (filter.filterIgnoreOperators && textDestination.isChannel) {
				if (textAuthor.isServer == NO) {
					if (senderUser == nil) {
						senderUser = [textDestination findMember:textAuthor.nickname];

						if (senderUser) {
							if (senderUser.halfOp) {
								/* User is at least a Half-op, ignore this filter. */

								continue;
							}
						} else {
							LogToConsoleDebug("senderUser == nil — Skipping to next filter");

							continue;
						}
					}
				}
			}

			if ([self testFilterMatch:filter againstText:text allowingNilText:NO] == NO) {
				continue;
			}

			/* Perform actions defined by filter */
			XRPerformBlockAsynchronouslyOnMainQueue(^{
				[self performActionForFilter:filter
						 withOriginalMessage:text
								  authoredBy:textAuthor
								 destinedFor:textDestination
									onClient:client
							referenceMessage:nil];
			});

			/* Forward a copy of the message to a query? */
			NSString *filterForwardToDestination = filter.filterForwardToDestination;

			if (filterForwardToDestination.length > 0 && text.length > 0) {
				IRCChannel *destinationChannel = [client findChannelOrCreate:filterForwardToDestination isPrivateMessage:YES];

				NSString *fakeMessageCommand = nil;

				if (lineType == TVCLogLineTypePrivateMessage ||
					lineType == TVCLogLineTypePrivateMessageNoHighlight ||
					lineType == TVCLogLineTypeAction ||
					lineType == TVCLogLineTypeActionNoHighlight)
				{
					fakeMessageCommand = @"PRIVMSG";
				} else if (lineType == TVCLogLineTypeNotice) {
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
					 if (lineType == TVCLogLineTypeNotice) {
						 [client setUnreadStateForChannel:destinationChannel];
					 } else {
						 BOOL isHighlight = context.highlight;

						 if (isHighlight) {
							 [client setHighlightStateForChannel:destinationChannel];
						 }

						 [client setUnreadStateForChannel:destinationChannel isHighlight:isHighlight];
					 }
				 }];
			}

			if (filter.filterIgnoreContent) {
				return NO; // Ignore original content
			}

			/* Return once the first filter matches */
			return YES;
		} // @autorelease
	} // for

	return YES;
}

- (void)performActionForFilter:(TPI_ChatFilter *)filter withOriginalMessage:(nullable NSString *)text authoredBy:(IRCPrefix *)textAuthor destinedFor:(IRCChannel *)textDestination onClient:(IRCClient *)client referenceMessage:(nullable IRCMessage *)referenceMessage
{
	if ([self isItSafeToPerformActionForFilter:filter] == NO) {
		return;
	}

	if (text == nil) {
		text = @"";
	}

	/* Perform action */
	NSString *filterAction = filter.filterAction;

	if (filterAction.length == 0) {
		return;
	}

	#define _maybeReplaceValue(key, value)	\
		if (value == nil) {		\
			filterAction = [filterAction stringByReplacingOccurrencesOfString:(key) withString:@""];	\
		} else {	\
			filterAction = [filterAction stringByReplacingOccurrencesOfString:(key) withString:(value)];	\
		}

	#define _maybeReplaceParam(paramIndex, paramIndexString)		\
		if (paramIndex >= paramsCount) {	\
			filterAction = [filterAction stringByReplacingOccurrencesOfString:@paramIndexString withString:@""];		\
		} else {	\
			filterAction = [filterAction stringByReplacingOccurrencesOfString:@paramIndexString withString:params[paramIndex]];		\
		}

	_maybeReplaceValue(@"%_channelName_%", textDestination.name)
	_maybeReplaceValue(@"%_localNickname_%", client.userNickname)
	_maybeReplaceValue(@"%_networkName_%", client.networkName)
	_maybeReplaceValue(@"%_originalMessage_%", text)
	_maybeReplaceValue(@"%_senderNickname_%", textAuthor.nickname)
	_maybeReplaceValue(@"%_senderUsername_%", textAuthor.username)
	_maybeReplaceValue(@"%_senderAddress_%", textAuthor.address)
	_maybeReplaceValue(@"%_senderHostmask_%", textAuthor.hostmask)
	_maybeReplaceValue(@"%_serverAddress_%", client.serverAddress)

	NSArray *params = referenceMessage.params;

	NSUInteger paramsCount = params.count;

	_maybeReplaceParam(0, "%_Parameter_0_%")
	_maybeReplaceParam(1, "%_Parameter_1_%")
	_maybeReplaceParam(2, "%_Parameter_2_%")
	_maybeReplaceParam(3, "%_Parameter_3_%")
	_maybeReplaceParam(4, "%_Parameter_4_%")
	_maybeReplaceParam(5, "%_Parameter_5_%")
	_maybeReplaceParam(6, "%_Parameter_6_%")
	_maybeReplaceParam(7, "%_Parameter_7_%")
	_maybeReplaceParam(8, "%_Parameter_8_%")
	_maybeReplaceParam(9, "%_Parameter_9_%")

#undef _maybeReplaceParam

#undef _maybeReplaceValue

	NSArray *filterActions = [filterAction componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];

	for (__strong NSString *actionCommand in filterActions) {
		if (actionCommand.length > 1 &&
			[actionCommand hasPrefix:@"/"] &&
			[actionCommand hasPrefix:@"//"] == NO)
		{
			actionCommand = [actionCommand substringFromIndex:1];

			[client sendCommand:actionCommand];
		}
	}

	/* Log action to a private message */
	if (filter.filterLogMatch) {
		IRCChannel *filterActionReportQuery = [client findChannelOrCreate:@"Filter Actions" isUtility:YES];

		NSString *formattedMessage = nil;

		if (textDestination == nil) {
			formattedMessage = TPILocalizedString(@"TPI_ChatFilterExtension[yla-he]", filter.filterTitle, textAuthor.nickname);
		} else {
			formattedMessage = TPILocalizedString(@"TPI_ChatFilterExtension[jcm-xj]", filter.filterTitle, textAuthor.nickname, textDestination.name);
		}

		[client print:formattedMessage
				   by:nil
			inChannel:filterActionReportQuery
			   asType:TVCLogLineTypePrivateMessage
			  command:@"PRIVMSG"];

		[client setUnreadStateForChannel:filterActionReportQuery];
	}
}

- (BOOL)isItSafeToPerformActionForFilter:(TPI_ChatFilter *)filter
{
	NSUInteger floodControlInterval = filter.filterActionFloodControlInterval;

	if (floodControlInterval == 0) {
		return YES;
	}

	NSTimeInterval now = [NSDate timeIntervalSince1970];

	@synchronized (self.filterActionLastPerforms) {
		NSString *filterIdentifier = filter.uniqueIdentifier;

		NSTimeInterval filterLastPerform = [self.filterActionLastPerforms doubleForKey:filterIdentifier];

		if ((now - filterLastPerform) <= floodControlInterval) {
			LogToConsoleDebug("Not performing action because of flood control: %.2f %.2f",
				  now, filterLastPerform);

			return NO;
		}

		self.filterActionLastPerforms[filterIdentifier] = @(now);
	}

	return YES;
}

- (void)reloadFilterActionPerforms
{
	/* This rebuilds the -filterActionLastPerforms so that the only entries that
	 exist are 1) filters that still exist 2) filters that require a timer */
	@synchronized (self.filterActionLastPerforms) {
		NSMutableDictionary *filterLastPerformsOld = self.filterActionLastPerforms;

		NSMutableDictionary *filterLastPerformsNew = [NSMutableDictionary dictionary];

		NSArray *filters = self.parentObject.filterArrayController.content;

		for (TPI_ChatFilter *filter in filters) {
			@autoreleasepool {
				if (filter.filterActionFloodControlInterval == 0) {
					continue;
				}

				NSString *filterIdentifier = filter.uniqueIdentifier;

				NSNumber *filterLastPerform = filterLastPerformsOld[filterIdentifier];

				if (filterLastPerform == nil) {
					continue;
				}

				filterLastPerformsNew[filterIdentifier] = filterLastPerform;
			}
		}

		self.filterActionLastPerforms = filterLastPerformsNew;
	}
}

@end

NS_ASSUME_NONNULL_END
