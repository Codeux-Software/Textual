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

@property (nonatomic, assign) BOOL newItem;
@property (nonatomic, retain) AddressBook* ignore;
@property (nonatomic, retain) NSTextField *hostmask;
@property (nonatomic, retain) NSButton *ignorePublicMsg;
@property (nonatomic, retain) NSButton *ignorePrivateMsg;
@property (nonatomic, retain) NSButton *ignoreHighlights;
@property (nonatomic, retain) NSButton *ignoreNotices;
@property (nonatomic, retain) NSButton *ignoreCTCP;
@property (nonatomic, retain) NSButton *ignoreDCC;
@property (nonatomic, retain) NSButton *ignoreJPQE;
@property (nonatomic, retain) NSButton *notifyJoins;
@property (nonatomic, retain) NSButton *notifyWhoisJoins;
@property (nonatomic, retain) NSView *contentView;
@property (nonatomic, retain) NSView *notificationView;
@property (nonatomic, retain) NSView *ignoreItemView;

- (void)start;
@end

@interface NSObject (IgnoreItemSheetDelegate)
- (void)ignoreItemSheetOnOK:(AddressBookSheet*)sender;
- (void)ignoreItemSheetWillClose:(AddressBookSheet*)sender;
@end