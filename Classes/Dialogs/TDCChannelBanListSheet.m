/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
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
#import "TXGlobalModels.h"
#import "TLOLanguagePreferences.h"
#import "IRCClient.h"
#import "IRCChannel.h"
#import "TVCBasicTableView.h"
#import "TDCChannelBanListSheetPrivate.h"

NS_ASSUME_NONNULL_BEGIN

@interface TDCChannelBanListSheetEntry : NSObject
@property (nonatomic, copy) NSString *entryMask;
@property (nonatomic, copy) NSString *entryAuthor;
@property (readonly, copy) NSString *entryCreationDateString;
@property (nonatomic, copy, nullable) NSDate *entryCreationDate;
@end

@interface TDCChannelBanListSheet ()
@property (nonatomic, strong, readwrite) IRCClient *client;
@property (nonatomic, strong, readwrite) IRCChannel *channel;
@property (nonatomic, copy, readwrite) NSString *clientId;
@property (nonatomic, copy, readwrite) NSString *channelId;
@property (nonatomic, assign, readwrite) TDCChannelBanListSheetEntryType entryType;
@property (nonatomic, copy, readwrite, nullable) NSArray<NSString *> *listOfChanges;
@property (nonatomic, weak) IBOutlet NSTextField *headerTitleTextField;
@property (nonatomic, weak) IBOutlet TVCBasicTableView *entryTable;
@property (nonatomic, strong) IBOutlet NSArrayController *entryTableController;

- (IBAction)onUpdate:(id)sender;
- (IBAction)onRemoveEntry:(id)sender;
@end

@implementation TDCChannelBanListSheet

ClassWithDesignatedInitializerInitMethod

- (instancetype)initWithEntryType:(TDCChannelBanListSheetEntryType)entryType inChannel:(IRCChannel *)channel
{
	NSParameterAssert(channel != nil);

	if ((self = [super init])) {
		self.entryType = entryType;

		self.client = channel.associatedClient;
		self.clientId = channel.associatedClient.uniqueIdentifier;

		self.channel = channel;
		self.channelId = channel.uniqueIdentifier;

		[self prepareInitialState];

		return self;
	}

	return nil;
}

- (void)prepareInitialState
{
	[RZMainBundle() loadNibNamed:@"TDCChannelBanListSheet" owner:self topLevelObjects:nil];

	self.entryTable.sortDescriptors = @[
		[NSSortDescriptor sortDescriptorWithKey:@"entryCreationDate" ascending:NO selector:@selector(compare:)]
	];

	NSString *headerTitle = nil;

	if (self.entryType == TDCChannelBanListSheetBanEntryType) {
		headerTitle = TXTLS(@"TDCChannelBanListSheet[1000]", self.channel.name);
	} else if (self.entryType == TDCChannelBanListSheetBanExceptionEntryType) {
		headerTitle = TXTLS(@"TDCChannelBanListSheet[1001]", self.channel.name);
	} else if (self.entryType == TDCChannelBanListSheetInviteExceptionEntryType) {
		headerTitle = TXTLS(@"TDCChannelBanListSheet[1002]", self.channel.name);
	} else if (self.entryType == TDCChannelBanListSheetQuietEntryType) {
		headerTitle = TXTLS(@"TDCChannelBanListSheet[1003]", self.channel.name);
	}

	self.headerTitleTextField.stringValue = headerTitle;
}

- (void)start
{
	[self startSheet];
}

- (void)clear
{
	self.entryTableController.content = nil;
}

- (void)addEntry:(NSString *)entryMask setBy:(nullable NSString *)entryAuthor creationDate:(nullable NSDate *)entryCreationDate
{
	NSParameterAssert(entryMask != nil);

	if (entryAuthor == nil) {
		entryAuthor = TXTLS(@"BasicLanguage[1002]"); // "Unknown"
	}

	TDCChannelBanListSheetEntry *newEntry = [TDCChannelBanListSheetEntry new];

	newEntry.entryMask = entryMask;
	newEntry.entryAuthor = entryAuthor;
	newEntry.entryCreationDate = entryCreationDate;

	[self willChangeValueForKey:@"entryCount"];

	[self.entryTableController addObject:newEntry];

	[self didChangeValueForKey:@"entryCount"];
}

- (NSString *)modeSymbol
{
	if (self.entryType == TDCChannelBanListSheetBanEntryType) {
		return @"b";
	} else if (self.entryType == TDCChannelBanListSheetBanExceptionEntryType) {
		return @"e";
	} else if (self.entryType == TDCChannelBanListSheetInviteExceptionEntryType) {
		return @"I";
	} else if (self.entryType == TDCChannelBanListSheetQuietEntryType) {
		return @"q";
	}

	return nil;
}

- (NSNumber *)entryCount
{
	return @([self.entryTableController.arrangedObjects count]);
}

#pragma mark -
#pragma mark Actions

- (void)onUpdate:(id)sender
{
	[self clear];

	if ([self.delegate respondsToSelector:@selector(channelBanListSheetOnUpdate:)]) {
		[self.delegate channelBanListSheetOnUpdate:self];
	}
}

- (void)onRemoveEntry:(id)sender
{
	NSIndexSet *selectedRows = self.entryTable.selectedRowIndexes;

	NSMutableArray<NSString *> *selectedEntries = [NSMutableArray arrayWithCapacity:selectedRows.count];

	[selectedRows enumerateIndexesUsingBlock:^(NSUInteger index, BOOL *stop) {
		TDCChannelBanListSheetEntry *entryItem = self.entryTableController.arrangedObjects[index];

		[selectedEntries addObject:entryItem.entryMask];
	}];

	self.listOfChanges =
	[self.client compileListOfModeChangesForModeSymbol:self.modeSymbol
											 modeIsSet:NO
										modeParameters:selectedEntries];

	[super cancel:nil];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.delegate respondsToSelector:@selector(channelBanListSheetWillClose:)]) {
		[self.delegate channelBanListSheetWillClose:self];
	}
}

@end

#pragma mark -

@implementation TDCChannelBanListSheetEntry

- (NSString *)entryCreationDateString
{
	NSDate *entryCreationDate = self.entryCreationDate;

	if (entryCreationDate == nil) {
		return TXTLS(@"BasicLanguage[1002]"); // "Unknown"
	}

	return TXFormatDateLongStyle(entryCreationDate, YES);
}

@end

NS_ASSUME_NONNULL_END
