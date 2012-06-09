// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 09, 2012

@interface AddressBookSheet (Private)
- (void)updateButtons;
- (void)reloadChannelTable;
@end

@implementation AddressBookSheet

@synthesize ignore;
@synthesize delegate;
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

- (void)start
{
	if (self.ignore.entryType == ADDRESS_BOOK_IGNORE_ENTRY) {
		self.sheet = self.ignoreWindow;
		
		if (NSObjectIsNotEmpty(self.ignore.hostmask)) {
			[self.hostmask setStringValue:self.ignore.hostmask];
		} 
	} else {
		self.sheet = self.notifyWindow;
		
		if (NSObjectIsNotEmpty(self.ignore.hostmask)) {
			[self.nickname setStringValue:self.ignore.hostmask];
		} 
	}
	
	[self.ignorePublicMsg		setState:self.ignore.ignorePublicMsg];
	[self.ignorePrivateMsg		setState:self.ignore.ignorePrivateMsg];
	[self.ignoreHighlights		setState:self.ignore.ignoreHighlights];
	[self.ignoreNotices			setState:self.ignore.ignoreNotices];
	[self.ignoreCTCP			setState:self.ignore.ignoreCTCP];
	[self.ignoreJPQE			setState:self.ignore.ignoreJPQE];
	[self.notifyJoins			setState:self.ignore.notifyJoins];
	[self.ignorePMHighlights	setState:self.ignore.ignorePMHighlights];
	
	[self startSheet];
}

- (void)ok:(id)sender
{
	if (self.ignore.entryType == ADDRESS_BOOK_IGNORE_ENTRY) {
		self.ignore.hostmask = [self.hostmask stringValue];
	} else {
		self.ignore.hostmask = [self.nickname stringValue];
	}
	
	self.ignore.ignorePublicMsg		= [self.ignorePublicMsg state];
	self.ignore.ignorePrivateMsg	= [self.ignorePrivateMsg state];
	self.ignore.ignoreHighlights	= [self.ignoreHighlights state];
	self.ignore.ignoreNotices		= [self.ignoreNotices state];
	self.ignore.ignoreCTCP			= [self.ignoreCTCP state];
	self.ignore.ignoreJPQE			= [self.ignoreJPQE state];
	self.ignore.notifyJoins			= [self.notifyJoins state];
	self.ignore.ignorePMHighlights	= [self.ignorePMHighlights state];
	
	[self.ignore processHostMaskRegex];
	
	if ([self.delegate respondsToSelector:@selector(ignoreItemSheetOnOK:)]) {
		[self.delegate ignoreItemSheetOnOK:self];
	}
	
	[super ok:sender];
}

#pragma mark -
#pragma mark NSWindow Delegate

- (void)windowWillClose:(NSNotification *)note
{
	if ([self.delegate respondsToSelector:@selector(ignoreItemSheetWillClose:)]) {
		[self.delegate ignoreItemSheetWillClose:self];
	}
}

@end