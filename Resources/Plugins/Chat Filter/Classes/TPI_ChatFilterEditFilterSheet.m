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

#import "TPI_ChatFilterEditFilterSheet.h"

NS_ASSUME_NONNULL_BEGIN

@interface TPI_ChatFilterEditFilterSheet ()
@property (nonatomic, strong) TPI_ChatFilterMutable *filter;
@property (nonatomic, weak) IBOutlet NSTextField *filterMatchTextField;
@property (nonatomic, weak) IBOutlet NSTextField *filterSenderMatchTextField;
@property (nonatomic, weak) IBOutlet NSTextField *filterTitleTextField;
@property (nonatomic, weak) IBOutlet NSTextField *filterNotesTextField;
@property (nonatomic, weak) IBOutlet NSTextField *filterActionFloodControlIntervalTextField;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *filterEventNumericTextField;
@property (nonatomic, weak) IBOutlet TVCTextFieldWithValueValidation *filterForwardToDestinationTextField;
@property (nonatomic, weak) IBOutlet TVCAutoExpandingTokenField *filterActionTokenField;
@property (nonatomic, weak) IBOutlet NSTokenField *filterActionTokenChannelName;
@property (nonatomic, weak) IBOutlet NSTokenField *filterActionTokenLocalNickname;
@property (nonatomic, weak) IBOutlet NSTokenField *filterActionTokenNetworkName;
@property (nonatomic, weak) IBOutlet NSTokenField *filterActionTokenOriginalMessage;
@property (nonatomic, weak) IBOutlet NSTokenField *filterActionTokenSenderAddress;
@property (nonatomic, weak) IBOutlet NSTokenField *filterActionTokenSenderHostmask;
@property (nonatomic, weak) IBOutlet NSTokenField *filterActionTokenSenderNickname;
@property (nonatomic, weak) IBOutlet NSTokenField *filterActionTokenSenderUsername;
@property (nonatomic, weak) IBOutlet NSTokenField *filterActionTokenServerAddress;
@property (nonatomic, weak) IBOutlet NSView *filterLimitedToHostView;
@property (nonatomic, weak) IBOutlet NSView *filterLimitedToSelectionHostView;
@property (nonatomic, weak) IBOutlet NSMatrix *filterLimitToMatrix;
@property (nonatomic, weak) IBOutlet NSButton *filterIgnoreContentCheck;
@property (nonatomic, weak) IBOutlet NSButton *filterIgnoreOperatorsCheck;
@property (nonatomic, weak) IBOutlet NSButton *filterLogMatchCheck;
@property (nonatomic, weak) IBOutlet NSButton *filterEventPlainTextMessageCheck;
@property (nonatomic, weak) IBOutlet NSButton *filterEventActionMessageCheck;
@property (nonatomic, weak) IBOutlet NSButton *filterEventNoticeMessageCheck;
@property (nonatomic, weak) IBOutlet NSButton *filterEventUserJoinedChannelCheck;
@property (nonatomic, weak) IBOutlet NSButton *filterEventUserLeftChannelCheck;
@property (nonatomic, weak) IBOutlet NSButton *filterEventUserKickedFromChannelCheck;
@property (nonatomic, weak) IBOutlet NSButton *filterEventUserDisconnectedCheck;
@property (nonatomic, weak) IBOutlet NSButton *filterEventUserChangedNicknameCheck;
@property (nonatomic, weak) IBOutlet NSButton *filterEventChannelTopicReceivedCheck;
@property (nonatomic, weak) IBOutlet NSButton *filterEventChannelTopicChangedCheck;
@property (nonatomic, weak) IBOutlet NSButton *filterEventChannelModeReceivedCheck;
@property (nonatomic, weak) IBOutlet NSButton *filterEventChannelModeChangedCheck;
@property (nonatomic, weak) IBOutlet NSButton *filterLimitedToMyselfCheck;
@property (nonatomic, assign) BOOL filterIgnoreOperatorsCheckEnabled;
@property (nonatomic, copy) NSArray<NSString *> *filterActionAutoCompletedTokens;
@property (nonatomic, strong) IBOutlet TVCChannelSelectionViewController *filterLimitToSelectionOutlineView;

- (IBAction)viewFilterMatchHelpText:(id)sender;
- (IBAction)viewFilterActionHelpText:(id)sender;
- (IBAction)viewFilterSenderMatchHelpText:(id)sender;
- (IBAction)viewFilterForwardToDestinationHelpText:(id)sender;

- (IBAction)filterLimitedToMatrixChanged:(id)sender;
- (IBAction)filterIgnoreContentCheckChanged:(id)sender;
- (IBAction)filterEventTypeChanged:(id)sender;
- (IBAction)filterLimitedToMyselfChanged:(id)sender;
@end

#pragma mark -

@interface TPI_ChatFilterFilterActionToken : NSObject
@property (nonatomic, copy) NSString *token;
@property (nonatomic, copy, readonly, nullable) NSString *tokenTitle;

+ (TPI_ChatFilterFilterActionToken *)tokenWithToken:(NSString *)token;
+ (nullable TPI_ChatFilterFilterActionToken *)tokenWithTokenTitle:(NSString *)tokenTitle;

+ (NSArray *)tokens;
+ (NSArray *)tokenTitles;

+ (nullable NSString *)titleForToken:(NSString *)token;

+ (BOOL)isToken:(NSString *)token;
@end

#pragma mark -

@implementation TPI_ChatFilterEditFilterSheet

#pragma mark -
#pragma mark Primary Sheet Structure

- (instancetype)initWithFilter:(nullable TPI_ChatFilter *)filter
{
	if ((self = [super init])) {
		if (filter == nil) {
			self.filter = [TPI_ChatFilterMutable new];
		} else {
			self.filter = [filter mutableCopy];
		}

		[self prepareInitialState];

		return self;
	}

	return nil;
}

- (void)prepareInitialState
{
	(void)[TPIBundleFromClass() loadNibNamed:@"TPI_ChatFilterEditFilterSheet" owner:self topLevelObjects:nil];

	[self populateTokenFieldStringValues];

	[self setupTextFieldRules];

	[self loadFilter];

	[self updateEnabledStateOfSenderMatch];
	[self updateEnabledStateOfFilterEvents];
	[self updateEnableStateOfFilterActionTokenField];
	[self updateEnabledStateOfComponentsConstrainedByFilterEvents];
	[self updateVisibilityOfLimitedToTableHostView];

	[self toggleOkButton];

	[self.filterLimitToSelectionOutlineView attachToView:self.filterLimitedToSelectionHostView];
}

- (void)start
{
	[self startSheet];
}

- (void)loadFilter
{
	self.filterMatchTextField.stringValue = self.filter.filterMatch;

	[self setTokens:self.filter.filterAction inTokenField:self.filterActionTokenField];

	self.filterActionFloodControlIntervalTextField.integerValue = self.filter.filterActionFloodControlInterval;

	self.filterTitleTextField.stringValue = self.filter.filterTitle;
	self.filterNotesTextField.stringValue = self.filter.filterNotes;

	self.filterSenderMatchTextField.stringValue = self.filter.filterSenderMatch;

	self.filterForwardToDestinationTextField.stringValue = self.filter.filterForwardToDestination;

	self.filterIgnoreContentCheck.state = self.filter.filterIgnoreContent;

	self.filterLogMatchCheck.state = self.filter.filterLogMatch;

	self.filterLimitedToMyselfCheck.state = self.filter.filterLimitedToMyself;

	self.filterEventPlainTextMessageCheck.state = [self.filter isEventTypeEnabled:TPI_ChatFilterPlainTextMessageEventType];
	self.filterEventActionMessageCheck.state = [self.filter isEventTypeEnabled:TPI_ChatFilterActionMessageEventType];
	self.filterEventNoticeMessageCheck.state = [self.filter isEventTypeEnabled:TPI_ChatFilterNoticeMessageEventType];
	self.filterEventUserJoinedChannelCheck.state = [self.filter isEventTypeEnabled:TPI_ChatFilterUserJoinedChannelEventType];
	self.filterEventUserLeftChannelCheck.state = [self.filter isEventTypeEnabled:TPI_ChatFilterUserLeftChannelEventType];
	self.filterEventUserKickedFromChannelCheck.state = [self.filter isEventTypeEnabled:TPI_ChatFilterUserKickedFromChannelEventType];
	self.filterEventUserDisconnectedCheck.state = [self.filter isEventTypeEnabled:TPI_ChatFilterUserDisconnectedEventType];
	self.filterEventUserChangedNicknameCheck.state = [self.filter isEventTypeEnabled:TPI_ChatFilterUserChangedNicknameEventType];
	self.filterEventChannelTopicReceivedCheck.state = [self.filter isEventTypeEnabled:TPI_ChatFilterChannelTopicReceivedEventType];
	self.filterEventChannelTopicChangedCheck.state = [self.filter isEventTypeEnabled:TPI_ChatFilterChannelTopicChangedEventType];
	self.filterEventChannelModeReceivedCheck.state = [self.filter isEventTypeEnabled:TPI_ChatFilterChannelModeReceivedEventType];
	self.filterEventChannelModeChangedCheck.state = [self.filter isEventTypeEnabled:TPI_ChatFilterChannelModeChangedEventType];

	NSArray *filterEventsNumerics = self.filter.filterEventsNumerics;

	if (filterEventsNumerics) {
		NSString *filterEventsNumericsJoined = [filterEventsNumerics componentsJoinedByString:@", "];

		self.filterEventNumericTextField.stringValue = filterEventsNumericsJoined;
	} else {
		[self.filterEventNumericTextField performValidation];
	}

	NSCell *filterLimitedToMatrixCell = [self.filterLimitToMatrix cellWithTag:self.filter.filterLimitedToValue];

	[self.filterLimitToMatrix selectCell:filterLimitedToMatrixCell];

	NSArray *filterLimitedToClientsIDs = self.filter.filterLimitedToClientsIDs;
	NSArray *filterLimitedToChannelsIDs = self.filter.filterLimitedToChannelsIDs;

	self.filterLimitToSelectionOutlineView.selectedClientIds = filterLimitedToClientsIDs;
	self.filterLimitToSelectionOutlineView.selectedChannelIds = filterLimitedToChannelsIDs;
}

- (void)saveFilter
{
	self.filter.filterMatch = self.filterMatchTextField.stringValue;

	NSString *filterActionStringValue = [self stringValueForTokenField:self.filterActionTokenField];

	self.filter.filterAction = filterActionStringValue;

	NSInteger filterActionFloodControlInterval = self.filterActionFloodControlIntervalTextField.integerValue;

	if (filterActionFloodControlInterval < 0) {
		filterActionFloodControlInterval = 0;
	}

	self.filter.filterActionFloodControlInterval = filterActionFloodControlInterval;

	self.filter.filterTitle = self.filterTitleTextField.stringValue;
	self.filter.filterNotes = self.filterNotesTextField.stringValue;

	self.filter.filterSenderMatch = self.filterSenderMatchTextField.stringValue;

	self.filter.filterForwardToDestination = self.filterForwardToDestinationTextField.stringValue;

	self.filter.filterIgnoreOperators = (self.filterIgnoreOperatorsCheck.state == NSOnState);

	self.filter.filterIgnoreContent = (self.filterIgnoreContentCheck.state == NSOnState);

	self.filter.filterLimitedToValue = [self.filterLimitToMatrix selectedTag];

	self.filter.filterLogMatch = (self.filterLogMatchCheck.state == NSOnState);

	self.filter.filterLimitedToMyself = (self.filterLimitedToMyselfCheck.state == NSOnState);

	self.filter.filterEvents = [self compileFilterEvents];

	self.filter.filterEventsNumerics = [self compileFilterEventsNumericsOrReturnEmptyArray];

	self.filter.filterLimitedToClientsIDs = self.filterLimitToSelectionOutlineView.selectedClientIds;
	self.filter.filterLimitedToChannelsIDs = self.filterLimitToSelectionOutlineView.selectedChannelIds;
}

- (BOOL)filterIgnoreOperatorsCheckValue
{
	if (self.filterIgnoreOperatorsCheckEnabled == NO) {
		return NO;
	}

	return self.filter.filterIgnoreOperators;
}

- (void)setFilterIgnoreOperatorsCheckValue:(BOOL)filterIgnoreOperatorsCheckValue
{
	self.filter.filterIgnoreOperators = filterIgnoreOperatorsCheckValue;
}

- (NSArray<NSString *> *)compileFilterEventsNumericsOrReturnEmptyArray
{
	NSArray *filterEventNumerics = [self compileFilterEventsNumerics];

	if (filterEventNumerics == nil) {
		return @[];
	}

	return filterEventNumerics;
}

- (nullable NSArray<NSString *> *)compileFilterEventsNumerics
{
	NSString *numericsString = self.filterEventNumericTextField.value;

	NSArray *numerics = [numericsString componentsSeparatedByString:@","];

	NSMutableArray *filterEventsNumerics = nil; // Create later so we don't waste memory if error.

	for (__strong NSString *numeric in numerics) {
		numeric = numeric.trim;

		if (numeric.length == 0) {
			continue; // Empty segment. We can ignore.
		}

		if (numeric.numericOnly) {
			if (numeric.length > 3) {
				return nil; // Bad value, fail completely
			}

			// Convert to integer and back to remove leading zeros
			numeric = [NSString stringWithFormat:@"%ld", numeric.integerValue];
		} else if (numeric.alphabeticNumericOnly) {
			if (numeric.length > 20) {
				return nil; // Bad value, fail completely
			}

			numeric = numeric.uppercaseString;
		} else {
			return nil; // Bad value, fail completely
		}

		if (filterEventsNumerics == nil) {
			filterEventsNumerics = [NSMutableArray array];
		}

		if ([filterEventsNumerics containsObject:numeric] == NO) {
			[filterEventsNumerics addObject:numeric];
		}
	}

	return [filterEventsNumerics copy];
}

- (TPI_ChatFilterEventType)compileFilterEvents
{
	TPI_ChatFilterEventType filterEvents = 0;

	if (self.filterEventPlainTextMessageCheck.state == NSOnState)
		filterEvents |= TPI_ChatFilterPlainTextMessageEventType;

	if (self.filterEventActionMessageCheck.state == NSOnState)
		filterEvents |= TPI_ChatFilterActionMessageEventType;

	if (self.filterEventNoticeMessageCheck.state == NSOnState)
		filterEvents |= TPI_ChatFilterNoticeMessageEventType;

	if (self.filterEventUserJoinedChannelCheck.state == NSOnState)
		filterEvents |= TPI_ChatFilterUserJoinedChannelEventType;

	if (self.filterEventUserLeftChannelCheck.state == NSOnState)
		filterEvents |= TPI_ChatFilterUserLeftChannelEventType;

	if (self.filterEventUserKickedFromChannelCheck.state == NSOnState)
		filterEvents |= TPI_ChatFilterUserKickedFromChannelEventType;

	if (self.filterEventUserDisconnectedCheck.state == NSOnState)
		filterEvents |= TPI_ChatFilterUserDisconnectedEventType;

	if (self.filterEventUserChangedNicknameCheck.state == NSOnState)
		filterEvents |= TPI_ChatFilterUserChangedNicknameEventType;

	if (self.filterEventChannelTopicReceivedCheck.state == NSOnState)
		filterEvents |= TPI_ChatFilterChannelTopicReceivedEventType;

	if (self.filterEventChannelTopicChangedCheck.state == NSOnState)
		filterEvents |= TPI_ChatFilterChannelTopicChangedEventType;

	if (self.filterEventChannelModeReceivedCheck.state == NSOnState)
		filterEvents |= TPI_ChatFilterChannelModeReceivedEventType;

	if (self.filterEventChannelModeChangedCheck.state == NSOnState)
		filterEvents |= TPI_ChatFilterChannelModeChangedEventType;

	return filterEvents;
}

- (void)ok:(id)sender
{
	[self saveFilter];

	if ([self.delegate respondsToSelector:@selector(chatFilterEditFilterSheet:onOk:)]) {
		[self.delegate chatFilterEditFilterSheet:self onOk:[self.filter copy]];
	}

	[super ok:nil];
}

- (void)windowWillClose:(NSNotification *)note
{
	[RZNotificationCenter() removeObserver:self];

	if ([self.delegate respondsToSelector:@selector(chatFilterEditFilterSheetWillClose:)]) {
		[self.delegate chatFilterEditFilterSheetWillClose:self];
	}
}

#pragma mark -
#pragma mark Token Field Delegate

- (void)populateTokenFieldStringValues
{
	NSCharacterSet *emptyCharacterSet = [NSCharacterSet characterSetWithCharactersInString:@""];

	self.filterActionTokenField.tokenizingCharacterSet = emptyCharacterSet;

	self.filterActionTokenField.completionDelay = 0.2;

	[self setToken:@"%_channelName_%" inTokenField:self.filterActionTokenChannelName];
	[self setToken:@"%_localNickname_%" inTokenField:self.filterActionTokenLocalNickname];
	[self setToken:@"%_networkName_%" inTokenField:self.filterActionTokenNetworkName];
	[self setToken:@"%_originalMessage_%" inTokenField:self.filterActionTokenOriginalMessage];
	[self setToken:@"%_senderNickname_%" inTokenField:self.filterActionTokenSenderNickname];
	[self setToken:@"%_senderUsername_%" inTokenField:self.filterActionTokenSenderUsername];
	[self setToken:@"%_senderAddress_%" inTokenField:self.filterActionTokenSenderAddress];
	[self setToken:@"%_senderHostmask_%" inTokenField:self.filterActionTokenSenderHostmask];
	[self setToken:@"%_serverAddress_%" inTokenField:self.filterActionTokenServerAddress];
}

- (nullable NSArray *)tokenField:(NSTokenField *)tokenField readFromPasteboard:(NSPasteboard *)pboard
{
	NSString *stringContent = pboard.stringContent;

	return [self tokensFromString:stringContent];
}

- (BOOL)tokenField:(NSTokenField *)tokenField writeRepresentedObjects:(NSArray *)objects toPasteboard:(NSPasteboard *)pboard
{
	NSString *stringContent = [objects componentsJoinedByString:@""];

	pboard.stringContent = stringContent;

	return YES;
}

- (NSTokenStyle)tokenField:(NSTokenField *)tokenField styleForRepresentedObject:(id)representedObject
{
	if ([representedObject isKindOfClass:[TPI_ChatFilterFilterActionToken class]]) {
		return NSRoundedTokenStyle;
	}

	return NSPlainTextTokenStyle;
}

- (nullable NSString *)tokenField:(NSTokenField *)tokenField displayStringForRepresentedObject:(id)representedObject
{
	if ([representedObject isKindOfClass:[TPI_ChatFilterFilterActionToken class]]) {
		return [representedObject tokenTitle];
	}

	return representedObject;
}

#ifdef TXSystemIsOSXHighSierraOrLater
- (nullable id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString
#else
- (id)tokenField:(NSTokenField *)tokenField representedObjectForEditingString:(NSString *)editingString
#endif

{
	if (tokenField == self.filterActionTokenField) {
		NSArray *tokenTitles = [self.filterActionAutoCompletedTokens filteredArrayUsingPredicate:
				[NSPredicate predicateWithFormat:@"SELF beginswith[cd] %@", editingString]];

		if (tokenTitles.count > 0) {
			NSString *tokenTitle = tokenTitles.firstObject;

			return [TPI_ChatFilterFilterActionToken tokenWithTokenTitle:tokenTitle];
		}
	}

	return editingString;
}

- (nullable NSArray *)tokenField:(NSTokenField *)tokenField completionsForSubstring:(NSString *)substring indexOfToken:(NSInteger)tokenIndex indexOfSelectedItem:(nullable NSInteger *)selectedIndex
{
	if (tokenField == self.filterActionTokenField) {
		NSArray *tokenTitles = [TPI_ChatFilterFilterActionToken tokenTitles];

		NSArray *tokenTitlesFiltered = [tokenTitles filteredArrayUsingPredicate:
				[NSPredicate predicateWithFormat:@"SELF beginswith[cd] %@", substring]];

		self.filterActionAutoCompletedTokens = tokenTitlesFiltered;

		return tokenTitlesFiltered;
	}

	return nil;
}

- (void)performFilterActionTokenCompletion
{
	;
}

- (NSString *)stringValueForTokenField:(NSTokenField *)tokenField
{
	return [tokenField.objectValue componentsJoinedByString:@""];
}

- (void)setTokens:(NSString *)tokens inTokenField:(NSTokenField *)tokenField
{
	NSArray *tokenObjects = [self tokensFromString:tokens];

	tokenField.objectValue = tokenObjects;
}

- (void)setToken:(NSString *)token inTokenField:(NSTokenField *)tokenField
{
	 TPI_ChatFilterFilterActionToken *tokenObject =
	[TPI_ChatFilterFilterActionToken tokenWithToken:token];

	tokenField.objectValue = @[tokenObject];
}

- (NSArray *)tokensFromString:(nullable NSString *)string
{
	NSString *tokenString = string;

	if (tokenString == nil) {
		return @[];
	}

	NSMutableArray *tokens = [NSMutableArray array];

	NSInteger currentPosition = 0;

	NSInteger tokenStringLength = tokenString.length;

	while (currentPosition < tokenStringLength) {
		NSRange searchRange = NSMakeRange(currentPosition, (tokenStringLength - currentPosition));

		NSRange range = [tokenString rangeOfString:@"%_([a-zA-Z0-9_]+)_%"
										   options:NSRegularExpressionSearch
											 range:searchRange];

		if (range.location == NSNotFound) {
			NSString *tokenStringPrefix = [tokenString substringWithRange:searchRange];

			[tokens addObject:tokenStringPrefix];

			break;
		}

		NSRange tokenStringPrefixRange = NSMakeRange(currentPosition, (range.location - currentPosition));

		if (tokenStringPrefixRange.length > 0) {
			NSString *tokenStringPrefix = [tokenString substringWithRange:tokenStringPrefixRange];

			[tokens addObject:tokenStringPrefix];
		}

		NSString *tokenStringToken = [tokenString substringWithRange:range];

		if ([TPI_ChatFilterFilterActionToken isToken:tokenStringToken]) {
			 TPI_ChatFilterFilterActionToken *token =
			[TPI_ChatFilterFilterActionToken tokenWithToken:tokenStringToken];

			[tokens addObject:token];
		} else {
			[tokens addObject:tokenStringToken];
		}

		currentPosition = NSMaxRange(range);
	}

	if (tokens.count == 0) {
		[tokens addObject:tokenString];
	}

	return tokens;
}

#pragma mark -
#pragma mark Utilities

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
	if (control != self.filterActionTokenField && control != self.filterNotesTextField) {
		return NO;
	}

	NSRange selectedRange = [textView selectedRange];

	if (selectedRange.length > 0) {
		return NO;
	}

	if (commandSelector == @selector(insertNewline:))
	{
		NSRange editedRange = textView.textStorage.editedRange;

		if (editedRange.length > 1) {
			return NO;
		}

		[textView insertNewlineIgnoringFieldEditor:self];

		return YES;
	}

	return NO;
}

- (void)controlTextDidChange:(NSNotification *)notification
{
	[self toggleOkButton];
}

- (void)validatedTextFieldTextDidChange:(id)sender
{
	[self toggleOkButton];
}

- (void)toggleOkButton
{
	BOOL disabled = NO;

	if (self.filterTitleTextField.stringValue.length == 0) {
		disabled = YES;
	}

	if (disabled == NO) {
		if (self.filterEventNumericTextField.valueIsValid == NO) {
			disabled = YES;
		} else if (self.filterForwardToDestinationTextField.valueIsValid == NO) {
			disabled = YES;
		}
	}

	if (disabled == NO) {
		if (self.filterIgnoreContentCheck.state == NSOffState &&
			self.filterForwardToDestinationTextField.stringValue.length == 0)
		{
			if (self.filterActionTokenField.stringValue.length == 0) {
				disabled = YES;
			}
		}
	}

	self.okButton.enabled = (disabled == NO);
}

- (void)setupTextFieldRules
{
	/* "Forward To" text field */
	self.filterForwardToDestinationTextField.textDidChangeCallback = self;

	self.filterForwardToDestinationTextField.performValidationWhenEmpty = NO;

	self.filterForwardToDestinationTextField.onlyShowStatusIfErrorOccurs = YES;

	self.filterForwardToDestinationTextField.stringValueIsInvalidOnEmpty = NO;
	self.filterForwardToDestinationTextField.stringValueIsTrimmed = YES;
	self.filterForwardToDestinationTextField.stringValueUsesOnlyFirstToken = NO;

	self.filterForwardToDestinationTextField.validationBlock = ^BOOL(NSString *currentValue) {
		if (currentValue.length > 125) {
			return NO;
		}

		if ([XRRegularExpression string:currentValue isMatchedByRegex:@"^([a-zA-Z0-9\\-\\_\\s]+)$"] == NO) {
			return NO;
		}

		return YES;
	};

	/* "Numerics" text field */
	self.filterEventNumericTextField.textDidChangeCallback = self;

	self.filterEventNumericTextField.performValidationWhenEmpty = NO;

	self.filterEventNumericTextField.onlyShowStatusIfErrorOccurs = YES;

	self.filterEventNumericTextField.stringValueIsInvalidOnEmpty = NO;
	self.filterEventNumericTextField.stringValueIsTrimmed = NO;
	self.filterEventNumericTextField.stringValueUsesOnlyFirstToken = NO;

	self.filterEventNumericTextField.validationBlock = ^BOOL(NSString *currentValue) {
		return ([self compileFilterEventsNumerics] != nil);
	};
}

- (void)updateVisibilityOfLimitedToTableHostView
{
	if (self.filterLimitToMatrix.selectedTag == TPI_ChatFilterLimitToSpecificItemsValue) {
		self.filterLimitedToHostView.hidden = NO;
	} else {
		self.filterLimitedToHostView.hidden = YES;
	}
}

- (void)updateEnableStateOfFilterActionTokenField
{
	;
}

- (void)updateEnabledStateOfFilterEvents
{
	BOOL enabled = (self.filterLimitToMatrix.selectedTag != TPI_ChatFilterLimitToPrivateMessagesValue);

	self.filterEventUserJoinedChannelCheck.enabled = enabled;
	self.filterEventUserLeftChannelCheck.enabled = enabled;
	self.filterEventUserKickedFromChannelCheck.enabled = enabled;
	self.filterEventUserDisconnectedCheck.enabled = enabled;
	self.filterEventUserChangedNicknameCheck.enabled = enabled;
	self.filterEventChannelTopicReceivedCheck.enabled = enabled;
	self.filterEventChannelTopicChangedCheck.enabled = enabled;
	self.filterEventChannelModeReceivedCheck.enabled = enabled;
	self.filterEventChannelModeChangedCheck.enabled = enabled;
}

- (void)updateEnabledStateOfComponentsConstrainedByFilterEvents
{
	BOOL enabled = (self.filterEventPlainTextMessageCheck.state == NSOnState ||
					self.filterEventActionMessageCheck.state == NSOnState ||
					self.filterEventNoticeMessageCheck.state == NSOnState);

	self.filterIgnoreOperatorsCheckEnabled = enabled;

	[self willChangeValueForKey:@"filterIgnoreOperatorsCheckValue"];
	[self didChangeValueForKey:@"filterIgnoreOperatorsCheckValue"];
}

- (void)updateEnabledStateOfSenderMatch
{
	BOOL enabled = (self.filterLimitedToMyselfCheck.state == NSOffState);

	self.filterSenderMatchTextField.enabled = enabled;
}

- (void)filterLimitedToMyselfChanged:(id)sender
{
	[self updateEnabledStateOfSenderMatch];
}

- (void)filterEventTypeChanged:(id)sender
{
	[self updateEnabledStateOfComponentsConstrainedByFilterEvents];
}

- (void)viewFilterMatchHelpText:(id)sender
{
	[TLOpenLink openWithString:@"https://help.codeux.com/textual/Introduction-to-the-Chat-Filter-Addon.kb#faq-entry-1" inBackground:NO];
}

- (void)viewFilterActionHelpText:(id)sender
{
	[TLOpenLink openWithString:@"https://help.codeux.com/textual/Introduction-to-the-Chat-Filter-Addon.kb#faq-entry-2" inBackground:NO];
}

- (void)viewFilterSenderMatchHelpText:(id)sender
{
	[TLOpenLink openWithString:@"https://help.codeux.com/textual/Introduction-to-the-Chat-Filter-Addon.kb#faq-entry-3" inBackground:NO];
}

- (void)viewFilterForwardToDestinationHelpText:(id)sender
{
	[TLOpenLink openWithString:@"https://help.codeux.com/textual/Introduction-to-the-Chat-Filter-Addon.kb#faq-entry-4" inBackground:NO];
}

- (void)filterLimitedToMatrixChanged:(id)sender
{
	[self updateVisibilityOfLimitedToTableHostView];

	[self updateEnabledStateOfFilterEvents];
}

- (void)filterIgnoreContentCheckChanged:(id)sender
{
	[self updateEnableStateOfFilterActionTokenField];

	[self toggleOkButton];
}

@end

#pragma mark -
#pragma mark Token Object

@implementation TPI_ChatFilterFilterActionToken

+ (TPI_ChatFilterFilterActionToken *)tokenWithToken:(NSString *)token
{
	TPI_ChatFilterFilterActionToken *tokenField = [TPI_ChatFilterFilterActionToken new];

	tokenField.token = token;

	return tokenField;
}

+ (nullable TPI_ChatFilterFilterActionToken *)tokenWithTokenTitle:(NSString *)tokenTitle
{
	NSArray *tokenTitles = [TPI_ChatFilterFilterActionToken tokenTitles];

	NSInteger tokenTitleIndex = [tokenTitles indexOfObject:tokenTitle];

	if (tokenTitleIndex == NSNotFound) {
		return nil;
	}

	NSArray *tokens = [TPI_ChatFilterFilterActionToken tokens];

	NSString *token = tokens[tokenTitleIndex];

	return [TPI_ChatFilterFilterActionToken tokenWithToken:token];
}

+ (BOOL)isToken:(NSString *)token
{
	NSArray *tokens = [TPI_ChatFilterFilterActionToken tokens];

	return ([tokens indexOfObject:token] != NSNotFound);
}

+ (NSArray<NSString *> *)tokens
{
	/* The index of this array should match the index of -tokenTitles */
	static NSArray *tokens = nil;

	if (tokens == nil) {
		tokens = @[
		   @"%_channelName_%",
		   @"%_localNickname_%",
		   @"%_networkName_%",
		   @"%_originalMessage_%",
		   @"%_senderNickname_%",
		   @"%_senderUsername_%",
		   @"%_senderAddress_%",
		   @"%_senderHostmask_%",
		   @"%_serverAddress_%",
		   @"%_Parameter_0_%",
		   @"%_Parameter_1_%",
		   @"%_Parameter_2_%",
		   @"%_Parameter_3_%",
		   @"%_Parameter_4_%",
		   @"%_Parameter_5_%",
		   @"%_Parameter_6_%",
		   @"%_Parameter_7_%",
		   @"%_Parameter_8_%"
		];
	}

	return tokens;
}

+ (NSArray<NSString *> *)tokenTitles
{
	/* The index of this array should match the index of -tokens */
	static NSArray *tokens = nil;

	if (tokens == nil) {
		tokens = @[
		   TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0001]"),
		   TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0002]"),
		   TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0003]"),
		   TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0004]"),
		   TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0007]"),
		   TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0008]"),
		   TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0005]"),
		   TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0006]"),
		   TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0009]"),
		   TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0010][01]"),
		   TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0010][02]"),
		   TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0010][03]"),
		   TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0010][04]"),
		   TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0010][05]"),
		   TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0010][06]"),
		   TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0010][07]"),
		   TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0010][08]"),
		   TPILocalizedString(@"TPI_ChatFilterEditFilterSheet[0010][09]")
		];
	}

	return tokens;
}

+ (nullable NSString *)titleForToken:(NSString *)token
{
	NSArray *tokens = [TPI_ChatFilterFilterActionToken tokens];

	NSInteger tokenIndex = [tokens indexOfObject:token];

	if (tokenIndex == NSNotFound) {
		return nil;
	}

	NSArray *tokenTitles = [TPI_ChatFilterFilterActionToken tokenTitles];

	return tokenTitles[tokenIndex];
}

- (nullable NSString *)tokenTitle
{
	return [TPI_ChatFilterFilterActionToken titleForToken:self.token];
}

- (NSString *)description
{
	return self.token;
}

@end

NS_ASSUME_NONNULL_END
