// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "TextualApplication.h"

@implementation TDCWelcomeSheet

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"TDCWelcomeSheet" owner:self];
		
		self.channels = [NSMutableArray new];
	}
	
	return self;
}

- (void)show
{
	[self tableViewSelectionIsChanging:nil];
	[self updateOKButton];
	
	[self.nickText setStringValue:[TPCPreferences defaultNickname]];
	
	[self startSheet];
}

- (void)close
{
	self.delegate = nil;
	
	[self endSheet];
}

- (void)onOK:(id)sender
{
	NSMutableSet *set = [NSMutableSet set];
	
	NSMutableArray *chans = [NSMutableArray array];
	
	for (__strong NSString *s in self.channels) {
		if (NSObjectIsNotEmpty(s)) {
			if ([s isChannelName] == NO) {
				s = [@"#" stringByAppendingString:s];
			}
			
			if ([set containsObject:s] == NO) {
				[chans addObject:s];
				[set   addObject:s];
			}
		}
	}
	
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setBool:self.autoConnectCheck.state forKey:@"connectOnLaunch"];
	
	dic[@"channelList"] = chans;
	dic[@"identityNickname"] = self.nickText.stringValue;
	dic[@"serverAddress"] = [self.hostCombo.stringValue cleanedServerHostmask];
	
	if ([self.delegate respondsToSelector:@selector(welcomeSheet:onOK:)]) {
		[self.delegate welcomeSheet:self onOK:dic];
	}
	
	[self endSheet];
}

- (void)onCancel:(id)sender
{
	[self endSheet];
}

- (void)onAddChannel:(id)sender
{
	[self.channels safeAddObject:NSStringEmptyPlaceholder];
	
	[self.channelTable reloadData];
	
	NSInteger row = (self.channels.count - 1);
	
	[self.channelTable selectItemAtIndex:row];
	[self.channelTable editColumn:0 row:row withEvent:nil select:YES];
}

- (void)onDeleteChannel:(id)sender
{
	NSInteger n = [self.channelTable selectedRow];
	
	if (n >= 0) {
		[self.channels safeRemoveObjectAtIndex:n];
		
		[self.channelTable reloadData];
		
		NSInteger count = self.channels.count;
		if (count <= n) n = (count - 1);
		
		if (n >= 0) {
			[self.channelTable selectItemAtIndex:n];
		}
		
		[self tableViewSelectionIsChanging:nil];
	}
}

- (void)controlTextDidChange:(NSNotification *)note
{
	[self updateOKButton];
}

- (void)onHostComboChanged:(id)sender
{
	[self updateOKButton];
}

- (void)updateOKButton
{
	NSString *nick = self.nickText.stringValue;
	NSString *host = self.hostCombo.stringValue;
	
	BOOL enabled = (NSObjectIsNotEmpty(nick) && NSObjectIsNotEmpty(host));
	
	[self.okButton setEnabled:enabled];
}

#pragma mark -
#pragma mark NSTableViwe Delegate

- (void)textDidEndEditing:(NSNotification *)note
{
	NSInteger n = [self.channelTable editedRow];
	
	if (n >= 0) {
		NSString *s = [[note object] textStorage].string.copy;
		
		(self.channels)[n] = s;
		
		[self.channelTable reloadData];
		[self.channelTable selectItemAtIndex:n];
		
		[self tableViewSelectionIsChanging:nil];
	}
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)sender
{
	return self.channels.count;
}

- (id)tableView:(NSTableView *)sender objectValueForTableColumn:(NSTableColumn *)column row:(NSInteger)row
{
	return [self.channels safeObjectAtIndex:row];
}

- (void)tableViewSelectionIsChanging:(NSNotification *)note
{
	[self.deleteChannelButton setEnabled:([self.channelTable selectedRow] >= 0)];
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