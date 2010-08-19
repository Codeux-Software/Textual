// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "AddressBookSheet.h"

@interface AddressBookSheet (Private)
- (void)updateButtons;
- (void)reloadChannelTable;
@end

@implementation AddressBookSheet

@synthesize ignore;
@synthesize newItem;

#define WINDOW_TOOLBAR_HEIGHT 163

- (id)init
{
	if (self = [super init]) {
		[NSBundle loadNibNamed:@"AddressBookSheet" owner:self];
	}
	return self;
}

- (void)dealloc
{
	[ignore release];
	[super dealloc];
}

- (void)onMenuBarItemChanged:(id)sender {
	switch ([sender indexOfSelectedItem]) {
		case 0:
			[self firstPane:notificationView];
			break;
		case 1:
			[self firstPane:ignoreItemView];
			break;
		default:
			[self firstPane:notificationView];
			break;
	}
} 

- (void)firstPane:(NSView *)view {
	NSRect windowFrame = [sheet frame];
	windowFrame.size.height = [view frame].size.height + WINDOW_TOOLBAR_HEIGHT;
	windowFrame.size.width = [view frame].size.width;
	windowFrame.origin.y = NSMaxY([sheet frame]) - ([view frame].size.height + WINDOW_TOOLBAR_HEIGHT);
	
	if ([[contentView subviews] count] != 0) {
		[[[contentView subviews] safeObjectAtIndex:0] removeFromSuperview];
	}
	
	[sheet setFrame:windowFrame display:YES animate:YES];
	[contentView setFrame:[view frame]];
	[contentView addSubview:view];	
}

- (void)start
{
	if (!newItem) {
		[hostmask setStringValue:ignore.hostmask];
		[ignorePublicMsg setState:ignore.ignorePublicMsg];
		[ignorePrivateMsg setState:ignore.ignorePrivateMsg];
		[ignoreHighlights setState:ignore.ignoreHighlights];
		[ignoreNotices setState:ignore.ignoreNotices];
		[ignoreCTCP setState:ignore.ignoreCTCP];
		[ignoreDCC setState:ignore.ignoreDCC];
		[ignoreJPQE setState:ignore.ignoreJPQE];
		[notifyJoins setState:ignore.notifyJoins];
		[notifyWhoisJoins setState:ignore.notifyWhoisJoins];
		
	}
	
	[self startSheet];
	[self firstPane:ignoreItemView];
	[sheet recalculateKeyViewLoop];
}

- (void)ok:(id)sender
{
	if ([[hostmask stringValue] length]) {
		ignore.hostmask = [hostmask stringValue];
	} else {
		ignore.hostmask = nil;
	}
	
	ignore.ignorePublicMsg = [ignorePublicMsg state];
	ignore.ignorePrivateMsg = [ignorePrivateMsg state];
	ignore.ignoreHighlights = [ignoreHighlights state];
	ignore.ignoreNotices = [ignoreNotices state];
	ignore.ignoreCTCP = [ignoreCTCP state];
	ignore.ignoreDCC = [ignoreDCC state];
	ignore.ignoreJPQE = [ignoreJPQE state];
	ignore.notifyJoins = [notifyJoins state];
	ignore.notifyWhoisJoins = [notifyWhoisJoins state];
	
	[ignore.hostmaskRegex release];
	ignore.hostmaskRegex = nil;
	
	[ignore processHostMaskRegex];
	
	if ([delegate respondsToSelector:@selector(ignoreItemSheetOnOK:)]) {
		[delegate ignoreItemSheetOnOK:self];
	}
	
	[super ok:sender];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification*)note
{
	if ([delegate respondsToSelector:@selector(ignoreItemSheetWillClose:)]) {
		[delegate ignoreItemSheetWillClose:self];
	}
}

@synthesize hostmask;
@synthesize ignorePublicMsg;
@synthesize ignorePrivateMsg;
@synthesize ignoreHighlights;
@synthesize ignoreNotices;
@synthesize ignoreCTCP;
@synthesize ignoreDCC;
@synthesize ignoreJPQE;
@synthesize notifyJoins;
@synthesize notifyWhoisJoins;
@synthesize contentView;
@synthesize notificationView;
@synthesize ignoreItemView;
@end