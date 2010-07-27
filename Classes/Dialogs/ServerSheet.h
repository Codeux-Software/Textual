// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>
#import "IRCClientConfig.h"
#import "ListView.h"
#import "ChannelSheet.h"
#import "AddressBookSheet.h"
#import "SheetBase.h"

@interface ServerSheet : SheetBase
{
	NSInteger uid;
	IRCClientConfig* config;
	
	NSInteger initialTabTag;
	NSView *initalView;
	
	IBOutlet NSView *contentView;
	IBOutlet NSView *generalView;
	IBOutlet NSView *detailsView;
	IBOutlet NSView *onloginView;
	IBOutlet NSView *ignoresView;
	
	IBOutlet NSSegmentedControl *tabView;
	
	IBOutlet NSTextField* nameText;
	IBOutlet NSButton* autoReconnectCheck;
	IBOutlet NSButton* autoConnectCheck;
	
	IBOutlet NSTextField* hostCombo;
	IBOutlet NSButton* sslCheck;
	IBOutlet NSTextField* portText;
	
	IBOutlet NSTextField* nickText;
	IBOutlet NSTextField* passwordText;
	IBOutlet NSTextField* usernameText;
	IBOutlet NSTextField* realNameText;
	IBOutlet NSTextField* nickPasswordText;
	IBOutlet NSTextField* altNicksText;
	
	IBOutlet NSTextField* leavingCommentText;
	IBOutlet NSTextField* userInfoText;
	
	IBOutlet NSPopUpButton* encodingCombo;
	IBOutlet NSPopUpButton* fallbackEncodingCombo;
	
	IBOutlet NSPopUpButton* proxyCombo;
	IBOutlet NSTextField* proxyHostText;
	IBOutlet NSTextField* proxyPortText;
	IBOutlet NSTextField* proxyUserText;
	IBOutlet NSTextField* proxyPasswordText;
	
	IBOutlet ListView* channelTable;
	IBOutlet NSButton* addChannelButton;
	IBOutlet NSButton* editChannelButton;
	IBOutlet NSButton* deleteChannelButton;
	
	IBOutlet NSTextView* loginCommandsText;
	IBOutlet NSButton* invisibleCheck;
	
	IBOutlet ListView* ignoreTable;
	IBOutlet NSButton* addIgnoreButton;
	IBOutlet NSButton* editIgnoreButton;
	IBOutlet NSButton* deleteIgnoreButton;
	
	ChannelSheet* channelSheet;
	AddressBookSheet* ignoreSheet;
}

@property (assign) NSInteger uid;
@property (retain) IRCClientConfig* config;
@property NSInteger initialTabTag;
@property (retain) NSView *initalView;
@property (retain) NSView *contentView;
@property (retain) NSView *generalView;
@property (retain) NSView *detailsView;
@property (retain) NSView *onloginView;
@property (retain) NSView *ignoresView;
@property (retain) NSSegmentedControl *tabView;
@property (retain) NSTextField* nameText;
@property (retain) NSButton* autoReconnectCheck;
@property (retain) NSButton* autoConnectCheck;
@property (retain) NSTextField* hostCombo;
@property (retain) NSButton* sslCheck;
@property (retain) NSTextField* portText;
@property (retain) NSTextField* nickText;
@property (retain) NSTextField* passwordText;
@property (retain) NSTextField* usernameText;
@property (retain) NSTextField* realNameText;
@property (retain) NSTextField* nickPasswordText;
@property (retain) NSTextField* altNicksText;
@property (retain) NSTextField* leavingCommentText;
@property (retain) NSTextField* userInfoText;
@property (retain) NSPopUpButton* encodingCombo;
@property (retain) NSPopUpButton* fallbackEncodingCombo;
@property (retain) NSPopUpButton* proxyCombo;
@property (retain) NSTextField* proxyHostText;
@property (retain) NSTextField* proxyPortText;
@property (retain) NSTextField* proxyUserText;
@property (retain) NSTextField* proxyPasswordText;
@property (retain) ListView* channelTable;
@property (retain) NSButton* addChannelButton;
@property (retain) NSButton* editChannelButton;
@property (retain) NSButton* deleteChannelButton;
@property (retain) NSTextView* loginCommandsText;
@property (retain) NSButton* invisibleCheck;
@property (retain) ListView* ignoreTable;
@property (retain) NSButton* addIgnoreButton;
@property (retain) NSButton* editIgnoreButton;
@property (retain) NSButton* deleteIgnoreButton;
@property (retain) ChannelSheet* channelSheet;
@property (retain) AddressBookSheet* ignoreSheet;

- (void)startWithIgnoreTab:(BOOL)ignoreTab;
- (void)show;
- (void)close;

- (void)ok:(id)sender;
- (void)cancel:(id)sender;

- (void)hostComboChanged:(id)sender;

- (void)encodingChanged:(id)sender;
- (void)proxyChanged:(id)sender;

- (void)addChannel:(id)sender;
- (void)editChannel:(id)sender;
- (void)deleteChannel:(id)sender;

- (void)addIgnore:(id)sender;
- (void)editIgnore:(id)sender;
- (void)deleteIgnore:(id)sender;

- (void)onMenuBarItemChanged:(id)sender;
- (void)firstPane:(NSView *)view;
@end

@interface NSObject (ServerSheetDelegate)
- (void)ServerSheetOnOK:(ServerSheet*)sender;
- (void)ServerSheetWillClose:(ServerSheet*)sender;
@end