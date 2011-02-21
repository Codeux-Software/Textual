// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface AddressBookSheet : SheetBase
{
	IBOutlet NSTextField *hostmask;
	
	IBOutlet NSButton *ignorePublicMsg;
	IBOutlet NSButton *ignorePrivateMsg;
	IBOutlet NSButton *ignoreHighlights;
	IBOutlet NSButton *ignoreNotices;
	IBOutlet NSButton *ignoreCTCP;
	IBOutlet NSButton *ignoreJPQE;
	IBOutlet NSButton *notifyJoins;
	IBOutlet NSButton *notifyWhoisJoins;
	IBOutlet NSButton *ignorePMHighlights;
	
	IBOutlet NSView *contentView;
	IBOutlet NSView *notificationView;
	IBOutlet NSView *ignoreItemView;
	
	BOOL newItem;
	
	AddressBook *ignore;
}

@property (nonatomic, assign) BOOL newItem;
@property (nonatomic, retain) AddressBook *ignore;
@property (nonatomic, retain) NSTextField *hostmask;
@property (nonatomic, retain) NSButton *ignorePublicMsg;
@property (nonatomic, retain) NSButton *ignorePrivateMsg;
@property (nonatomic, retain) NSButton *ignoreHighlights;
@property (nonatomic, retain) NSButton *ignoreNotices;
@property (nonatomic, retain) NSButton *ignoreCTCP;
@property (nonatomic, retain) NSButton *ignoreJPQE;
@property (nonatomic, retain) NSButton *notifyJoins;
@property (nonatomic, retain) NSButton *notifyWhoisJoins;
@property (nonatomic, retain) NSButton *ignorePMHighlights;
@property (nonatomic, retain) NSView *contentView;
@property (nonatomic, retain) NSView *notificationView;
@property (nonatomic, retain) NSView *ignoreItemView;

- (void)onMenuBarItemChanged:(id)sender;
- (void)start;
@end

@interface NSObject (IgnoreItemSheetDelegate)
- (void)ignoreItemSheetOnOK:(AddressBookSheet *)sender;
- (void)ignoreItemSheetWillClose:(AddressBookSheet *)sender;
@end