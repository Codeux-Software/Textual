/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

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

#import "TextualApplication.h"

@interface TDCWelcomeSheet ()
@property (nonatomic, nweak) IBOutlet NSButton *autoConnectCheck;
@property (nonatomic, nweak) IBOutlet NSButton *addChannelButton;
@property (nonatomic, nweak) IBOutlet NSButton *deleteChannelButton;
@property (nonatomic, nweak) IBOutlet NSTextField *nicknameField;
@property (nonatomic, nweak) IBOutlet NSComboBox *serverAddressField;
@property (nonatomic, nweak) IBOutlet TVCBasicTableView *channelTable;
@property (nonatomic, strong) NSMutableArray *channelList;
@property (nonatomic, copy) NSDictionary *serverList;
@end

@implementation TDCWelcomeSheet

#pragma mark -
#pragma mark Init.

- (instancetype)init
{
	if ((self = [super init])) {
		[RZMainBundle() loadCustomNibNamed:@"TDCWelcomeSheet" owner:self topLevelObjects:nil];
		
		self.channelList = [NSMutableArray new];

		/* Load the list of available IRC networks. */
		NSString *slp = [RZMainBundle() pathForResource:@"IRCNetworks" ofType:@"plist"];
		
		self.serverList = [NSDictionary dictionaryWithContentsOfFile:slp];

		/* Populate the server address field with the IRC network list. */
		NSArray *sortedKeys = [self.serverList allKeys];

		sortedKeys = [sortedKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
			/* We are sorting keys. They are NSString values. */
			/* Sort without case so that "freenode" is under servers with a capital F. */
			return [obj1 compare:obj2 options:NSCaseInsensitiveSearch];
		}];
		
		for (NSString *key in sortedKeys) {
			[self.serverAddressField addItemWithObjectValue:key];
		}
	}
	
	return self;
}

#pragma mark -
#pragma mark Server List Factory

- (NSString *)nameMatchesServerInList:(NSString *)name
{
	for (NSString *key in self.serverList) {
		if ([name isEqualIgnoringCase:key]) {
			return key;
		}
	}

	return nil;
}

#pragma mark -
#pragma mark Controls

- (void)show
{
	[self tableViewSelectionIsChanging:nil];
	[self updateOKButton];

	[self.channelTable setTextEditingDelegate:self];
	
	[self.nicknameField setStringValue:[TPCPreferences defaultNickname]];
	
	[self startSheet];
}

- (void)close
{
	[super cancel:nil];
}

- (void)releaseTableViewDataSourceBeforeSheetClosure
{
	[self.channelTable setDelegate:nil];
	[self.channelTable setDataSource:nil];
}

- (void)ok:(id)sender
{
	IRCClientConfig *newConfig = [IRCClientConfig new];
	
	/* Get actaul server. */
	NSString *userServAddress = [self.serverAddressField firstTokenStringValue];
	
	NSString *realhost = [self nameMatchesServerInList:userServAddress];
	
	if (realhost == nil) {
		realhost = [userServAddress cleanedServerHostmask];
	} else {
		realhost = self.serverList[realhost];
	}
	
	/* Complete basic information. */
	BOOL autoConnect = [self.autoConnectCheck state];
	
	NSString *nickname = [self.nicknameField firstTokenStringValue];
	
	[newConfig setClientName:realhost];
	[newConfig setServerAddress:realhost];
	[newConfig setAutoConnect:autoConnect];
	[newConfig setNickname:nickname];
	
	/* Populate channels. */
	NSMutableArray *channels = [NSMutableArray array];
	
	for (NSString *s in self.channelList) {
		NSString *t = [s trim];
		
		if ([t length] > 0) {
			if ([t isChannelName] == NO) {
				 t = [@"#" stringByAppendingString:s];
			}
			
			IRCChannelConfig *cc = [IRCChannelConfig seedWithName:t];

			[channels addObjectWithoutDuplication:cc];
		}
	}
	
	[newConfig setChannelList:channels];

	/* Inform delegate and finish. */
	if ([self.delegate respondsToSelector:@selector(welcomeSheet:onOK:)]) {
		[self.delegate welcomeSheet:self onOK:newConfig];
	}

	[super ok:nil];
}

- (void)onAddChannel:(id)sender
{
	[self.channelList addObject:NSStringEmptyPlaceholder];
	
	[self.channelTable reloadData];
	
	NSInteger row = ([self.channelList count] - 1);
	
	[self.channelTable selectItemAtIndex:row];
	
	[self.channelTable editColumn:0 row:row withEvent:nil select:YES];
}

- (void)onDeleteChannel:(id)sender
{
	NSInteger n = [self.channelTable selectedRow];
	
	if (n > -1) {
		[self.channelList removeObjectAtIndex:n];

		[self.channelTable reloadData];
		
		NSInteger count = [self.channelList count];
		
		if (count <= n) {
			n = (count - 1);
		}
		
		if (n >= 0) {
			[self.channelTable selectItemAtIndex:n];
		}
		
		[self tableViewSelectionIsChanging:nil];
	}
}

- (void)controlTextDidChange:(NSNotification *)note
{
	[self askAboutTheSupportChannel];
	
	[self updateOKButton];
}

- (void)onServerAddressChanged:(id)sender
{
	[self askAboutTheSupportChannel];
	
	[self updateOKButton];
}

- (void)askAboutTheSupportChannel
{
	NSString *host = [self.serverAddressField stringValue];

	if ([host hasSuffix:@"freenode.net"] || [host isEqualIgnoringCase:@"freenode"]) {
		NSString *key = [TLOPopupPrompts suppressionKeyWithBase:@"welcomesheet_join_support_channel"];

		BOOL enableDialog = [RZUserDefaults() boolForKey:key];

		if (enableDialog == NO) {
			BOOL addSupportChannel = [TLOPopupPrompts dialogWindowWithQuestion:TXTLS(@"TDCWelcomeSheet[1000][2]")
																		 title:TXTLS(@"TDCWelcomeSheet[1000][1]")
																 defaultButton:BLS(1219)
															   alternateButton:BLS(1182)
																suppressionKey:@"welcomesheet_join_support_channel"
															   suppressionText:TLOPopupPromptSpecialSuppressionTextValue];

			if (addSupportChannel) {
				[self.channelList addObjectWithoutDuplication:@"#textual"];

				[self.channelTable reloadData];
			}
		}
	}
}

- (void)updateOKButton
{
	NSString *nick = [self.nicknameField trimmedStringValue];
	NSString *host = [self.serverAddressField trimmedStringValue];
	
	BOOL enabled = (NSObjectIsNotEmpty(nick) && NSObjectIsNotEmpty(host));
	
	[self.okButton setEnabled:enabled];
}

#pragma mark -
#pragma mark NSTextView Delegate (for support channel link)

- (BOOL)textView:(NSTextView *)textView clickedOnLink:(NSURL *)link atIndex:(NSUInteger)charIndex
{
	if ([[link absoluteString] hasPrefix:@"textual://"]) {
		[self cancel:nil];

		return NO; // Tell delegate we did not handle it.
	}

	return YES;
}

#pragma mark -
#pragma mark NSTableView Delegate

- (void)textDidEndEditing:(NSNotification *)note
{
	NSInteger n = [self.channelTable editedRow];
	
	if (n > -1) {
		NSString *s = [[[[note object] textStorage] string] copy];
		
		self.channelList[n] = s;
		
		[self.channelTable reloadData];
		[self.channelTable selectItemAtIndex:n];
		
		[self tableViewSelectionIsChanging:nil];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	return [self.channelList count];
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	return self.channelList[row];
}

- (void)tableViewSelectionIsChanging:(NSNotification *)note
{
	[self.deleteChannelButton setEnabled:([self.channelTable selectedRow] > -1)];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.delegate respondsToSelector:@selector(welcomeSheetWillClose:)]) {
		[self.delegate welcomeSheetWillClose:self];
	}
}

@end
