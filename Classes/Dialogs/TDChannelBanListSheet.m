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

#import "TextualApplication.h"

@interface TDChannelBanListSheetEntry : NSObject
@property (nonatomic, copy) NSString *entryMask;
@property (nonatomic, copy) NSString *entryAuthor;
@property (readonly, copy) NSString *entryCreationDateString;
@property (nonatomic, copy) NSDate *entryCreationDate;
@end

@interface TDChannelBanListSheet ()
@property (nonatomic, copy, readwrite) NSArray *changeModeList;
@property (nonatomic, weak) IBOutlet NSTextField *headerTitleTextField;
@property (nonatomic, weak) IBOutlet TVCBasicTableView *entryTable;
@property (nonatomic, strong) IBOutlet NSArrayController *entryTableController;

- (IBAction)onUpdate:(id)sender;
- (IBAction)onRemoveEntry:(id)sender;
@end

@implementation TDChannelBanListSheet

- (instancetype)init
{
    if ((self = [super init])) {
		[RZMainBundle() loadNibNamed:@"TDChannelBanListSheet" owner:self topLevelObjects:nil];

		[self.entryTable setSortDescriptors:@[
			[NSSortDescriptor sortDescriptorWithKey:@"entryCreationDate" ascending:NO selector:@selector(compare:)]
		]];
    }
    
    return self;
}

- (void)show
{
	IRCChannel *c = [worldController() findChannelByClientId:self.clientID channelId:self.channelID];

	NSString *headerTitle = nil;

	if (self.entryType == TDChannelBanListSheetBanEntryType) {
		headerTitle = TXTLS(@"TDChannelBanListSheet[1000]", [c name]);
	} else if (self.entryType == TDChannelBanListSheetBanExceptionEntryType) {
		headerTitle = TXTLS(@"TDChannelBanListSheet[1001]", [c name]);
	} else if (self.entryType == TDChannelBanListSheetInviteExceptionEntryType) {
		headerTitle = TXTLS(@"TDChannelBanListSheet[1002]", [c name]);
	}

	[self.headerTitleTextField setStringValue:headerTitle];

	[self startSheet];
}

- (void)clear
{
	[self.entryTableController setContent:nil];
}

- (void)addEntry:(NSString *)entryMask setBy:(NSString *)entryAuthor creationDate:(NSDate *)entryCreationDate
{
	TDChannelBanListSheetEntry *newEntry = [TDChannelBanListSheetEntry new];

	[newEntry setEntryMask:entryMask];
	[newEntry setEntryAuthor:entryAuthor];
	[newEntry setEntryCreationDate:entryCreationDate];

	[self willChangeValueForKey:@"entryCount"];

	[self.entryTableController addObject:newEntry];

	[self didChangeValueForKey:@"entryCount"];
}

- (NSString *)mode
{
	if (self.entryType == TDChannelBanListSheetBanEntryType) {
		return @"b";
	} else if (self.entryType == TDChannelBanListSheetBanExceptionEntryType) {
		return @"e";
	} else if (self.entryType == TDChannelBanListSheetInviteExceptionEntryType) {
		return @"I";
	}

	return nil;
}

- (NSNumber *)entryCount
{
	return @([[self.entryTableController arrangedObjects] count]);
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
	IRCClient *client = [worldController() findClientById:self.clientID];

	NSMutableArray *changeArray = [NSMutableArray array];

	NSMutableString *modeSetString = [NSMutableString string];
	NSMutableString *modeParamString = [NSMutableString string];

	NSInteger currentIndex = 0;

	NSArray *selectedRows = [self.entryTable selectedRows];

	for (NSNumber *indexNumber in selectedRows) {
		NSInteger index = [indexNumber unsignedIntegerValue];

		TDChannelBanListSheetEntry *item = [self.entryTableController arrangedObjects][index];

		if (currentIndex == 0) {
			[modeSetString appendFormat:@"-%@", [self mode]];
		} else {
			[modeSetString appendString:[self mode]];
		}

		[modeParamString appendFormat:@" %@", [item entryMask]];

		currentIndex += 1;

		if (currentIndex == [[client supportInfo] modesCount]) {
			NSString *combinedModeSet = [modeSetString stringByAppendingString:modeParamString];

			[changeArray addObject:combinedModeSet];

			[modeSetString setString:NSStringEmptyPlaceholder];
			[modeParamString setString:NSStringEmptyPlaceholder];

			currentIndex = 0;
		}
	}

	if (NSObjectIsEmpty(modeSetString) == NO && NSObjectIsEmpty(modeParamString) == NO) {
		NSString *combinedModeSet = [modeSetString stringByAppendingString:modeParamString];

		[changeArray addObject:combinedModeSet];
	}

	self.changeModeList = changeArray;

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

@implementation TDChannelBanListSheetEntry

- (NSString *)entryCreationDateString
{
	if (self.entryCreationDate == nil) {
		return TXTLS(@"BasicLanguage[1002]"); // "Unknown"
	} else {
		return TXFormatDateTimeStringToCommonFormat(self.entryCreationDate, NO);
	}
}

@end
