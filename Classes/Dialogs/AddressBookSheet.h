// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>
#import "SheetBase.h"
#import "AddressBook.h"
#import "ListView.h"

@interface AddressBookSheet : SheetBase
{
	IBOutlet NSTextField *hostmask;
	
	IBOutlet NSButton *ignorePublicMsg;
	IBOutlet NSButton *ignorePrivateMsg;
	IBOutlet NSButton *ignoreHighlights;
	IBOutlet NSButton *ignoreNotices;
	IBOutlet NSButton *ignoreCTCP;
	IBOutlet NSButton *ignoreDCC;
	IBOutlet NSButton *ignoreJPQE;
	IBOutlet NSButton *notifyJoins;
	IBOutlet NSButton *notifyWhoisJoins;
	
	IBOutlet NSView *contentView;
	IBOutlet NSView *notificationView;
	IBOutlet NSView *ignoreItemView;
	
	BOOL newItem;
	AddressBook* ignore;
}

- (void)onMenuBarItemChanged:(id)sender;
- (void)firstPane:(NSView *)view;

@property (assign) BOOL newItem;
@property (retain) AddressBook* ignore;
@property (retain) NSTextField *hostmask;
@property (retain) NSButton *ignorePublicMsg;
@property (retain) NSButton *ignorePrivateMsg;
@property (retain) NSButton *ignoreHighlights;
@property (retain) NSButton *ignoreNotices;
@property (retain) NSButton *ignoreCTCP;
@property (retain) NSButton *ignoreDCC;
@property (retain) NSButton *ignoreJPQE;
@property (retain) NSButton *notifyJoins;
@property (retain) NSButton *notifyWhoisJoins;
@property (retain) NSView *contentView;
@property (retain) NSView *notificationView;
@property (retain) NSView *ignoreItemView;

- (void)start;
@end

@interface NSObject (IgnoreItemSheetDelegate)
- (void)ignoreItemSheetOnOK:(AddressBookSheet*)sender;
- (void)ignoreItemSheetWillClose:(AddressBookSheet*)sender;
@end