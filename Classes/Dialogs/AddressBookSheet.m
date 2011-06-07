// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface AddressBookSheet (Private)
- (void)updateButtons;
- (void)reloadChannelTable;
@end

@implementation AddressBookSheet

@synthesize ignore;
@synthesize newItem;
@synthesize hostmask;
@synthesize nickname;
@synthesize ignorePublicMsg;
@synthesize ignorePrivateMsg;
@synthesize ignoreHighlights;
@synthesize ignoreNotices;
@synthesize ignoreCTCP;
@synthesize ignoreJPQE;
@synthesize notifyJoins;
@synthesize ignorePMHighlights;
@synthesize ignoreWindow;
@synthesize notifyWindow;

- (id)init
{
	if ((self = [super init])) {
		[NSBundle loadNibNamed:@"AddressBookSheet" owner:self];
	}

	return self;
}

- (void)dealloc
{
	[ignore drain];
	
	[super dealloc];
}

- (void)start
{
	if (ignore.entryType == ADDRESS_BOOK_IGNORE_ENTRY) {
		self.sheet = ignoreWindow;
		
		if (NSObjectIsNotEmpty(ignore.hostmask)) {
			[hostmask setStringValue:ignore.hostmask];
		} 
	} else {
		self.sheet = notifyWindow;
		
		if (NSObjectIsNotEmpty(ignore.hostmask)) {
			[nickname setStringValue:ignore.hostmask];
		} 
	}
	
	[ignorePublicMsg	setState:ignore.ignorePublicMsg];
	[ignorePrivateMsg	setState:ignore.ignorePrivateMsg];
	[ignoreHighlights	setState:ignore.ignoreHighlights];
	[ignoreNotices		setState:ignore.ignoreNotices];
	[ignoreCTCP			setState:ignore.ignoreCTCP];
	[ignoreJPQE			setState:ignore.ignoreJPQE];
	[notifyJoins		setState:ignore.notifyJoins];
	[ignorePMHighlights setState:ignore.ignorePMHighlights];
	
	[self startSheet];
}

- (void)ok:(id)sender
{
	if (ignore.entryType == ADDRESS_BOOK_IGNORE_ENTRY) {
		ignore.hostmask = [hostmask stringValue];
	} else {
		ignore.hostmask = [nickname stringValue];
	}
	
	ignore.ignorePublicMsg		= [ignorePublicMsg state];
	ignore.ignorePrivateMsg		= [ignorePrivateMsg state];
	ignore.ignoreHighlights		= [ignoreHighlights state];
	ignore.ignoreNotices		= [ignoreNotices state];
	ignore.ignoreCTCP			= [ignoreCTCP state];
	ignore.ignoreJPQE			= [ignoreJPQE state];
	ignore.notifyJoins			= [notifyJoins state];
	ignore.ignorePMHighlights	= [ignorePMHighlights state];
	
	[ignore processHostMaskRegex];
	
	if ([delegate respondsToSelector:@selector(ignoreItemSheetOnOK:)]) {
		[delegate ignoreItemSheetOnOK:self];
	}
	
	[super ok:sender];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([delegate respondsToSelector:@selector(ignoreItemSheetWillClose:)]) {
		[delegate ignoreItemSheetWillClose:self];
	}
}

@end