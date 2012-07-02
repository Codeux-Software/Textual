// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface TDCAddressBookSheet : TDCSheetBase
@property (nonatomic, assign) BOOL newItem;
@property (nonatomic, strong) IRCAddressBook *ignore;
@property (nonatomic, strong) NSTextField *hostmask;
@property (nonatomic, strong) NSTextField *nickname;
@property (nonatomic, strong) NSButton *ignorePublicMsg;
@property (nonatomic, strong) NSButton *ignorePrivateMsg;
@property (nonatomic, strong) NSButton *ignoreHighlights;
@property (nonatomic, strong) NSButton *ignoreNotices;
@property (nonatomic, strong) NSButton *ignoreCTCP;
@property (nonatomic, strong) NSButton *ignoreJPQE;
@property (nonatomic, strong) NSButton *notifyJoins;
@property (nonatomic, strong) NSButton *ignorePMHighlights;
@property (nonatomic, strong) NSWindow *ignoreWindow;
@property (nonatomic, strong) NSWindow *notifyWindow;

- (void)start;
@end

@interface NSObject (TXIgnoreItemSheetDelegate)
- (void)ignoreItemSheetOnOK:(TDCAddressBookSheet *)sender;
- (void)ignoreItemSheetWillClose:(TDCAddressBookSheet *)sender;
@end