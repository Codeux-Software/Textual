// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface AddressBookSheet : SheetBase
{
	IBOutlet NSTextField *hostmask;
	IBOutlet NSTextField *nickname;
	
	IBOutlet NSButton *ignorePublicMsg;
	IBOutlet NSButton *ignorePrivateMsg;
	IBOutlet NSButton *ignoreHighlights;
	IBOutlet NSButton *ignoreNotices;
	IBOutlet NSButton *ignoreCTCP;
	IBOutlet NSButton *ignoreJPQE;
	IBOutlet NSButton *notifyJoins;
	IBOutlet NSButton *ignorePMHighlights;
	
	IBOutlet NSWindow *ignoreWindow;
	IBOutlet NSWindow *notifyWindow;
	
	BOOL newItem;
	
	AddressBook *ignore;
}

@property (assign) BOOL newItem;
@property (strong) AddressBook *ignore;
@property (strong) NSTextField *hostmask;
@property (strong) NSTextField *nickname;
@property (strong) NSButton *ignorePublicMsg;
@property (strong) NSButton *ignorePrivateMsg;
@property (strong) NSButton *ignoreHighlights;
@property (strong) NSButton *ignoreNotices;
@property (strong) NSButton *ignoreCTCP;
@property (strong) NSButton *ignoreJPQE;
@property (strong) NSButton *notifyJoins;
@property (strong) NSButton *ignorePMHighlights;
@property (strong) NSWindow *ignoreWindow;
@property (strong) NSWindow *notifyWindow;

- (void)start;
@end

@interface NSObject (IgnoreItemSheetDelegate)
- (void)ignoreItemSheetOnOK:(AddressBookSheet *)sender;
- (void)ignoreItemSheetWillClose:(AddressBookSheet *)sender;
@end