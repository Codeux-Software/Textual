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

@property (nonatomic, assign) BOOL newItem;
@property (nonatomic, retain) AddressBook *ignore;
@property (nonatomic, retain) NSTextField *hostmask;
@property (nonatomic, retain) NSTextField *nickname;
@property (nonatomic, retain) NSButton *ignorePublicMsg;
@property (nonatomic, retain) NSButton *ignorePrivateMsg;
@property (nonatomic, retain) NSButton *ignoreHighlights;
@property (nonatomic, retain) NSButton *ignoreNotices;
@property (nonatomic, retain) NSButton *ignoreCTCP;
@property (nonatomic, retain) NSButton *ignoreJPQE;
@property (nonatomic, retain) NSButton *notifyJoins;
@property (nonatomic, retain) NSButton *ignorePMHighlights;
@property (nonatomic, retain) NSWindow *ignoreWindow;
@property (nonatomic, retain) NSWindow *notifyWindow;

- (void)start;
@end

@interface NSObject (IgnoreItemSheetDelegate)
- (void)ignoreItemSheetOnOK:(AddressBookSheet *)sender;
- (void)ignoreItemSheetWillClose:(AddressBookSheet *)sender;
@end