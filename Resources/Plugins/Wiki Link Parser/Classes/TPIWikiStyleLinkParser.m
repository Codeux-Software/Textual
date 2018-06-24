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

#import "TPIWikiStyleLinkParser.h"

/* Link prefix storage is a remnant of older times.
 There are better ways to store them other than an array with specific
 index values, but because this plugin is optional and rarely needs any
 maintaining, its not a priority to make it any better. */
#define _indexChannelId				0
#define _indexLinkPrefix			1

#define _linkMatchRegex             @"\\[\\[([^\\]]+)\\]\\]"

@interface TPIWikiStyleLinkParser ()
@property (nonatomic, copy) NSArray *linkPrefixes;
@property (nonatomic, strong) IBOutlet NSView *preferencePane;
@property (nonatomic, strong) IBOutlet NSWindow *rnewConditionWindow;
@property (nonatomic, weak) IBOutlet TVCValidatedTextField *rnewConditionLinkPrefixField;
@property (nonatomic, weak) IBOutlet NSPopUpButton *rnewConditionChannelPopup;
@property (nonatomic, weak) IBOutlet NSButton *rnewConditionSaveButton;
@property (nonatomic, weak) IBOutlet NSButton *rnewConditionCancelButton;
@property (nonatomic, weak) IBOutlet NSButton *addConditionButton;
@property (nonatomic, weak) IBOutlet NSButton *removeConditionButton;
@property (nonatomic, weak) IBOutlet NSTableView *linkPrefixesTable;

- (void)addCondition:(id)sender;
- (void)removeCondition:(id)sender;

- (void)saveNewCondition:(id)sender;
- (void)cancelNewCondition:(id)sender;

- (void)updateNewConditionWindowSaveButton:(id)sender;
@end

@implementation TPIWikiStyleLinkParser

#pragma mark -
#pragma mark Init

- (void)pluginLoadedIntoMemory
{
	[self performBlockOnMainThread:^{
		[self linkPrefixesStorageRead];

		[TPIBundleFromClass() loadNibNamed:@"TPIWikiStyleLinkParser" owner:self topLevelObjects:nil];

		[self.rnewConditionLinkPrefixField setStringValueIsInvalidOnEmpty:YES];

		[self.rnewConditionLinkPrefixField setTextDidChangeCallback:self];

		[self.rnewConditionLinkPrefixField setValidationBlock:^NSString *(NSString *currentValue) {
			NSURL *URLValue = [NSURL URLWithString:currentValue];

			if (URLValue == nil) {
				return TPILocalizedString(@"BasicLanguage[535-5j]");
			}

			return nil;
		}];

		[self updateRemoveConditionButton];
	}];
}

#pragma mark -
#pragma mark Server Input.

- (NSString *)willRenderMessage:(NSString *)newMessage forViewController:(TVCLogController *)logController lineType:(TVCLogLineType)lineType memberType:(TVCLogLineMemberType)memberType
{
	if ([self processWikiStyleLinks] == NO) {
		return nil;
	}
	
	/* Only work on plain text messages */
	if (lineType == TVCLogLinePrivateMessageType ||
		lineType == TVCLogLineActionType)
	{
		IRCChannel *channel = [logController associatedChannel];
		
		NSString *linkPrefix = [self linkPrefixFromId:[channel uniqueIdentifier]];

		if (linkPrefix == nil) {
			return nil;
		}

		NSMutableString *muteString = [newMessage mutableCopy];
		
		while (1 == 1) {
			NSRange linkRange = [XRRegularExpression string:muteString rangeOfRegex:_linkMatchRegex];

			if (linkRange.location == NSNotFound) {
				break;
			} else if (linkRange.length < 5) {
				continue;
			}
			
			/* Get inside of brackets */
			NSRange cutRange = NSMakeRange((linkRange.location + 2),
										   (linkRange.length - 4));
			
			NSString *linkInside = [muteString substringWithRange:cutRange];
			
			/* Get the left side */
			NSInteger insideBarPosition = [linkInside stringPosition:@"|"];

			if (insideBarPosition > 0) {
				linkInside = [linkInside substringToIndex:insideBarPosition];

				linkInside = [linkInside trim];
			}

			linkInside = [linkInside percentEncodedString];

			linkInside = [linkPrefix stringByAppendingString:linkInside];
			
			[muteString replaceCharactersInRange:linkRange withString:linkInside];
		}
		
		return muteString;
	}
	
	return nil;
}

#pragma mark -
#pragma mark Preference Pane.

- (NSString *)pluginPreferencesPaneMenuItemName
{
    return TPILocalizedString(@"BasicLanguage[0vq-yu]");
}

- (NSView *)pluginPreferencesPaneView
{
    return self.preferencePane;
}

#pragma mark -
#pragma mark Table View delegate

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
	[self updateRemoveConditionButton];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
	return [self.linkPrefixes count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
	NSString *columnId = [tableColumn identifier];

	NSArray *entryInfo = self.linkPrefixes[row];

	if ([columnId isEqualToString:@"channel"]) {
		NSString *entryName = [self channelNameFromId:entryInfo[_indexChannelId]];

		if (entryName == nil) {
			return TPILocalizedString(@"BasicLanguage[sb5-c9]");
		}

		return entryName;
	} else if ([columnId isEqualToString:@"link"]) {
		return entryInfo[_indexLinkPrefix];
	}

	return nil;
}

#pragma mark -
#pragma mark Table View Actions

- (void)removeCondition:(id)sender
{
	NSInteger selectedRow = [self.linkPrefixesTable selectedRow];

	if (selectedRow < 0) {
		return;
	}

	NSMutableArray *linkPrefixes = [self.linkPrefixes mutableCopy];

	[linkPrefixes removeObjectAtIndex:selectedRow];

	self.linkPrefixes = linkPrefixes;

	[self linkPrefixesStorageSave];

	[self.linkPrefixesTable reloadData];
}

- (void)updateRemoveConditionButton
{
	NSInteger selectedRow = [self.linkPrefixesTable selectedRow];

	[self.removeConditionButton setEnabled:(selectedRow >= 0)];
}

#pragma mark -
#pragma mark Condition Management

- (void)validatedTextFieldTextDidChange:(id)sender
{
	if (sender == self.rnewConditionLinkPrefixField) {
		[self updateNewConditionWindowSaveButton:nil];
	}
}

- (void)addCondition:(id)sender
{
	[self.rnewConditionLinkPrefixField setStringValue:NSStringEmptyPlaceholder];

	[self.rnewConditionChannelPopup removeAllItems];

	[self.addConditionButton setEnabled:NO];
	[self.removeConditionButton setEnabled:NO];

	NSMutableArray *listOfTrackedIds = [NSMutableArray array];

	for (NSArray *entry in self.linkPrefixes) {
		[listOfTrackedIds addObject:entry[_indexChannelId]];
	}

	for (IRCClient *u in [worldController() clientList]) {
		/* Record information about the channel list */
		NSArray *channelList = [u channelList];

		NSInteger channelCount = [channelList count];

		if (channelCount == 0) {
			continue;
		}

		/* Create new menu item for client */
		NSMenuItem *clientMenuItem = [NSMenuItem new];

		[clientMenuItem setEnabled:NO];

		[clientMenuItem setTitle:[u name]];

		[[self.rnewConditionChannelPopup menu] addItem:clientMenuItem];

		/* Filter channel list */
		for (IRCChannel *c in channelList) {
			if ([c isChannel] == NO) {
				continue;
			}

			NSString *channelId = [c uniqueIdentifier];
			
			/* Do we already track it? */
			BOOL channelTracked = [listOfTrackedIds containsObject:channelId];

			if (channelTracked) {
				channelCount -= 1; // Decrease channel count by one

				continue;
			}

			/* Create new menu item for channel */
			NSString *channelName = [NSString stringWithFormat:@"    %@", [c name]];

			NSMenuItem *channelMenuItem = [NSMenuItem new];

			[channelMenuItem setEnabled:YES];

			[channelMenuItem setTitle:channelName];

			[channelMenuItem setUserInfo:channelId];

			[[self.rnewConditionChannelPopup menu] addItem:channelMenuItem];
		}

		/* Remove the client title? */
		if (channelCount <= 0) {
			[[self.rnewConditionChannelPopup menu] removeItem:clientMenuItem];
		}
	}

	listOfTrackedIds = nil;

	/* Present window */
	[NSApp beginSheet:self.rnewConditionWindow
	   modalForWindow:[NSApp keyWindow]
		modalDelegate:self
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];

	[self.rnewConditionWindow makeFirstResponder:self.rnewConditionLinkPrefixField];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[sheet close];
}

- (void)saveNewCondition:(id)sender
{
	if ([self validateLinkPrefix] == NO) {
		return;
	}

	NSMutableArray *linkPrefixes = [self.linkPrefixes mutableCopy];

	NSString *linkPrefix = [self.rnewConditionLinkPrefixField stringValue];

	NSMenuItem *channelMenuItem = [self.rnewConditionChannelPopup selectedItem];
	NSString *channelId = [channelMenuItem userInfo];

	[linkPrefixes addObjectWithoutDuplication:@[channelId, linkPrefix]];

	self.linkPrefixes = linkPrefixes;

	[self linkPrefixesStorageSave];

	[self.linkPrefixesTable reloadData];

	[self cancelNewCondition:nil];
}

- (void)cancelNewCondition:(id)sender
{
	[self.addConditionButton setEnabled:YES];
	[self.removeConditionButton setEnabled:YES];

	[NSApp endSheet:self.rnewConditionWindow];

	[self updateRemoveConditionButton];
}

- (void)updateNewConditionWindowSaveButton:(id)sender
{
	BOOL condition2 = [[self.rnewConditionChannelPopup selectedItem] isEnabled];

	[self.rnewConditionSaveButton setEnabled:condition2];
}

- (BOOL)validateLinkPrefix
{
	BOOL condition1 = [self.rnewConditionLinkPrefixField valueIsValid];

	if (condition1 == NO) {
		[self.rnewConditionLinkPrefixField showValidationErrorPopover];

		return NO;
	}

	return YES;
}

#pragma mark -
#pragma mark Utilities

- (BOOL)processWikiStyleLinks
{
    return [RZUserDefaults() boolForKey:@"Wiki-style Link Parser Extension -> Service Enabled"];
}

- (void)linkPrefixesStorageRead
{
	NSArray *linkPrefixes = [RZUserDefaults() arrayForKey:@"Wiki-style Link Parser Extension -> Link Prefixes"];

	if (linkPrefixes == nil) {
		linkPrefixes = @[];
	}

	self.linkPrefixes = linkPrefixes;
}

- (void)linkPrefixesStorageSave
{
	[RZUserDefaults() setObject:self.linkPrefixes forKey:@"Wiki-style Link Parser Extension -> Link Prefixes"];
}

- (NSString *)channelNameFromId:(NSString *)itemId
{
	for (IRCClient *u in [worldController() clientList]) {
		for (IRCChannel *c in [u channelList]) {
			if ([[c uniqueIdentifier] isEqualToString:itemId]) {
				return [c name];
			}
		}
	}

	return nil;
}

- (NSString *)linkPrefixFromId:(NSString *)itemId
{
	for (NSArray *entry in self.linkPrefixes) {
		if ([entry[_indexChannelId] isEqualToString:itemId]) {
			return entry[_indexLinkPrefix];
		}
	}

	return nil;
}

@end
