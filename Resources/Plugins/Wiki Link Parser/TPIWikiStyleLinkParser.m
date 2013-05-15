/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
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

#import "TPIWikiStyleLinkParser.h"

#define _linkMatchRegex             @"\\[\\[([^\\]]+)\\]\\]"

@interface TPIWikiStyleLinkParser ()
@property (nonatomic, weak) NSView *preferencePane;
@property (nonatomic, unsafe_unretained) NSWindow *rnewConditionWindow;
@property (nonatomic, weak) NSTextField *rnewConditionLinkPrefixField;
@property (nonatomic, weak) NSPopUpButton *rnewConditionChannelPopup;
@property (nonatomic, weak) NSButton *rnewConditionSaveButton;
@property (nonatomic, weak) NSButton *rnewConditionCancelButton;
@property (nonatomic, weak) NSButton *addConditionButton;
@property (nonatomic, weak) NSButton *removeConditionButton;
@property (nonatomic, weak) NSTableView *linkPrefixesTable;
@property (nonatomic, strong) NSMutableDictionary *rnewConditionChannelMatrix;

- (void)addCondition:(id)sender;
- (void)removeCondition:(id)sender;

- (void)saveNewCondition:(id)sender;
- (void)cancelNewCondition:(id)sender;

- (void)updateNewConditionWindowSaveButton:(id)sender;
@end

@implementation TPIWikiStyleLinkParser

#pragma mark -
#pragma mark Init.

- (void)pluginLoadedIntoMemory:(IRCWorld *)world
{
    [NSBundle loadNibNamed:@"TPIWikiStyleLinkParser" owner:self];
	
	[self updateRemoveConditionButton];
}

#pragma mark -
#pragma mark Server Input.

- (void)messageReceivedByServer:(IRCClient *)client
                         sender:(NSDictionary *)senderDict
                        message:(NSDictionary *)messageDict
{
    NSAssertReturn([self processWikiStyleLinks]);
	
	/* Gather information about message. */
    NSArray *params = messageDict[@"messageParamaters"];

	NSString *message = messageDict[@"messageSequence"];

	IRCChannel *channel = [client findChannel:params[0]];

    PointerIsEmptyAssert(channel);

	NSString *linkPrefix = [self linkPrefixFromID:channel.config.itemUUID];

	NSObjectIsEmptyAssert(linkPrefix);

    /* Parse the message for all possible matches. */
    NSArray *linkMatches = [TLORegularExpression matchesInString:[message stripIRCEffects] withRegex:_linkMatchRegex];

    if (linkMatches.count > 0) {
        NSInteger loopIndex = 0;

        /* Loop through each match. */
        for (__strong NSString *linkRaw in linkMatches) {
            NSAssertReturnLoopContinue(linkRaw.length > 4);

            loopIndex += 1;

            /* Get the inside of the brackets. */
            NSRange cutRange = NSMakeRange(2, (linkRaw.length - 4));

            linkRaw = [linkRaw safeSubstringWithRange:cutRange];

            /* Get the left side. */
            if ([linkRaw contains:@"|"]) {
                linkRaw = [linkRaw safeSubstringToIndex:[linkRaw stringPosition:@"|"]];
                linkRaw = [linkRaw trim];
            }

            /* Create our message and post it. */
            NSString *message = [NSString stringWithFormat:@" %i: %@ —> %@%@", loopIndex, linkRaw, linkPrefix, [linkRaw encodeURIComponent]];

            [client printDebugInformation:message channel:channel];
        }
    }
}

- (NSArray *)pluginSupportsServerInputCommands
{
    return @[@"privmsg"];
}

#pragma mark -
#pragma mark User Input.

- (id)interceptUserInput:(id)input command:(NSString *)command
{
	/* Return input if we are not going to process anything. */
    NSAssertReturnR([self processWikiStyleLinks], input);

    /* Do not handle NSString. */
    if ([input isKindOfClass:[NSAttributedString class]] == NO) {
        return input;
    }

	/* Link prefix. */
	IRCChannel *channel = self.worldController.selectedChannel;

	NSString *linkPrefix = [self linkPrefixFromID:channel.config.itemUUID];

	NSObjectIsEmptyAssertReturn(linkPrefix, input);

    /* Start parser. */
    NSMutableAttributedString *muteString = [input mutableCopy];

    while (1 == 1) {
        /* Get the range of next match. */
        NSRange linkRange = [TLORegularExpression string:[muteString string] rangeOfRegex:_linkMatchRegex];

        /* No match found? Break our loop. */
        if (linkRange.location == NSNotFound) {
            break;
        }

        NSAssertReturnLoopContinue(linkRange.length > 4);

        /* Get inside of brackets. */
        NSRange cutRange = NSMakeRange((linkRange.location + 2),
                                       (linkRange.length - 4));

        NSString *linkInside;

        linkInside = [muteString.string safeSubstringWithRange:cutRange];

        /* Get the left side. */
        if ([linkInside contains:@"|"]) {
            linkInside = [linkInside safeSubstringToIndex:[linkInside stringPosition:@"|"]];
            linkInside = [linkInside trim];
        }

        /* Build our link and replace it in the input. */
        linkInside = [linkPrefix stringByAppendingString:linkInside.encodeURIComponent];

        [muteString replaceCharactersInRange:linkRange withString:linkInside];
    }

    return muteString;
}

#pragma mark -
#pragma mark Preference Pane.

- (NSString *)preferencesMenuItemName
{
    return TPILS(@"WikiStyleLinkParserPreferencePaneMenuItemTitle");
}

- (NSView *)preferencesView
{
    return self.preferencePane;
}

#pragma mark -
#pragma mark Table delegate. 

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
	NSArray *entryInfo = self.linkPrefixes[row];

	NSAssertReturnR((entryInfo.count == 2), nil);

	if ([tableColumn.identifier isEqualToString:@"channel"]) {
		NSString *entryName = [self channelNameFromID:entryInfo[0]];

		NSObjectIsEmptyAssertReturn(entryName, TPILS(@"WikiStyleLinkParserChannelNoLongerExists"));

		return entryName;
	} else {
		return entryInfo[1];
	}
}

#pragma mark -
#pragma mark Condition Management.

- (void)controlTextDidChange:(NSNotification *)obj
{
	[self updateNewConditionWindowSaveButton:nil];
}

- (void)addCondition:(id)sender
{
	/* Reset conditions. */
	[self.rnewConditionLinkPrefixField setStringValue:NSStringEmptyPlaceholder];

	[self.rnewConditionChannelPopup removeAllItems];

	/* Disable adding new conditions when we are already doing one. */
	[self.addConditionButton setEnabled:NO];
	[self.removeConditionButton setEnabled:NO];

	/* We need some way to match the tag to the UUID of the channel we
	 want to track. To do that, we keep a dictionary matching the tags
	 to the UUID of each channel. That way, when the user picks a channel
	 in the "New Condition" dialog we only have to reference the tag and
	 then we have the UUID that we need saved. We do not save the actual
	 channel names. We save the UUID of that channel since it is unique,
	 always and forever. Even between restarts. */
	self.rnewConditionChannelMatrix = [NSMutableDictionary dictionary];

	NSInteger channelTag = 1;

	/* Start populating. */
	for (IRCClient *u in self.worldController.clients) {
		/* We keep track of the number of channels we add because we do not add
		 channels that we do not already track. Therefore, if our count is zero,
		 then we have to know so we do not add the client title. */
		NSInteger channelCount = 0;

		/* Add the client title. */
		NSMenuItem *umi = [NSMenuItem new];

		[umi setEnabled:NO]; // Do not let user pick only a client.
		[umi setTitle:u.config.clientName];

		[self.rnewConditionChannelPopup.menu addItem:umi];

		/* Build list of channels part of this client. */
		for (IRCChannel *c in u.channels) {
			/* Do we already track it? */
			NSString *existingPrefix = [self linkPrefixFromID:c.config.itemUUID];

			if (NSObjectIsNotEmpty(existingPrefix)) {
				continue;
			}

			/* Add item. */
			NSMenuItem *cmi = [NSMenuItem new];

			/* Create the menu. */
			[cmi setEnabled:YES];
			[cmi setTag:channelTag];
			[cmi setTitle:[NSString stringWithFormat:@"    %@", c.name]];

			/* Update the tag --> UUID dictionary. */
			[self.rnewConditionChannelMatrix setObject:c.config.itemUUID forKey:@(channelTag)];

			/* Add the actual menu item. */
			[self.rnewConditionChannelPopup.menu addItem:cmi];

			/* Bump the tag by one. */
			channelTag += 1;
			channelCount += 1;
		}

		/* Remove the client title? */
		if (channelCount <= 0) {
			[self.rnewConditionChannelPopup.menu removeItem:umi];
		}
	}

	/* Pop the new window and center it. */
	[NSApp beginSheet:self.rnewConditionWindow
	   modalForWindow:[NSApp keyWindow]
		modalDelegate:self
	   didEndSelector:@selector(sheetDidEnd:returnCode:contextInfo:)
		  contextInfo:nil];

	/* Make text field the first responder. */
	[self.rnewConditionWindow makeFirstResponder:self.rnewConditionLinkPrefixField];

	/* Update save button state. */
	[self updateNewConditionWindowSaveButton:nil];
}

- (void)sheetDidEnd:(NSWindow *)sheet returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	[sheet close];
}

- (void)removeCondition:(id)sender
{
	NSInteger selectedRow = self.linkPrefixesTable.selectedRow;

	NSAssertReturn(selectedRow >= 0);

	/* Get the old links. */
	NSMutableArray *mutOldPrefixes = [self.linkPrefixes mutableCopy];

	/* Remove the old. */
	[mutOldPrefixes removeObjectAtIndex:selectedRow];

	/* Update defaults. */
	[RZUserDefaults() setObject:mutOldPrefixes forKey:@"Wiki-style Link Parser Extension -> Link Prefixes"];

	/* Reload the table. */
	[self.linkPrefixesTable reloadData];
}

- (void)saveNewCondition:(id)sender
{
	/* Get the old links. */
	NSMutableArray *mutOldPrefixes = [self.linkPrefixes mutableCopy];

	/* Get the information to save. */
	NSString *linkPrefix = self.rnewConditionLinkPrefixField.stringValue;

	NSString *channelUUID = [self.rnewConditionChannelMatrix objectForKey:@(self.rnewConditionChannelPopup.selectedTag)];

	/* Add to dictionary. */
	[mutOldPrefixes safeAddObjectWithoutDuplication:@[channelUUID, linkPrefix]];

	/* Update defaults. */
	[RZUserDefaults() setObject:mutOldPrefixes forKey:@"Wiki-style Link Parser Extension -> Link Prefixes"];

	/* Clear the matrix. */
	self.rnewConditionChannelMatrix = nil;

	/* Reload the table. */
	[self.linkPrefixesTable reloadData];
	
	/* Update buttons and close window. */
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
	BOOL cond1 = (self.rnewConditionLinkPrefixField.stringValue.length > 0);
	BOOL cond2 = (self.rnewConditionChannelPopup.selectedTag > 0);

	[self.rnewConditionSaveButton setEnabled:(cond1 && cond2)];
}

- (void)updateRemoveConditionButton
{
	NSInteger selectedRow = self.linkPrefixesTable.selectedRow;

	[self.removeConditionButton setEnabled:(selectedRow >= 0)];
}

#pragma mark -
#pragma mark Utilities.

- (BOOL)processWikiStyleLinks
{
    return [RZUserDefaults() boolForKey:@"Wiki-style Link Parser Extension -> Service Enabled"];
}

/* -linkPrefixes returns an array of all link prefixes. Each link prefix is stored as an 
 array with the first index being the channel UUID and the second as the actual link. 
 Template: @[<channel UUID>, <link prefix>] */

- (NSArray *)linkPrefixes
{
	NSArray *prefixes = [RZUserDefaults() arrayForKey:@"Wiki-style Link Parser Extension -> Link Prefixes"];

	PointerIsEmptyAssertReturn(prefixes, [NSArray array]);

	return prefixes;
}

/* This will scan the Textual server tree for the actual UUID and return the
 channel name matching the UUID that we have. */
- (NSString *)channelNameFromID:(NSString *)itemUUID
{
	/* Textual does not have any mapping methods so we have to actually scan 
	 every server and every channel to find our ID. */

	NSObjectIsEmptyAssertReturn(itemUUID, nil);

	for (IRCClient *u in self.worldController.clients) {
		for (IRCChannel *c in u.channels) {
			if ([c.config.itemUUID isEqualToString:itemUUID]) {
				return c.name;
			}
		}
	}

	return nil;
}

/* This will scan our actual link prefix array for the UUID. */
- (NSString *)linkPrefixFromID:(NSString *)itemUUID
{
	NSObjectIsEmptyAssertReturn(itemUUID, nil);
	
	for (NSArray *entry in self.linkPrefixes) {
		NSAssertReturnLoopContinue(entry.count == 2);

		NSString *entryUUID = entry[0];
		NSString *entryLink = entry[1];

		if ([itemUUID isEqualToString:entryUUID]) {
			return entryLink;
		}
	}

	return nil;
}

@end
