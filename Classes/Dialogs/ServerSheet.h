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
	IRCClient* client;
	IRCClientConfig* config;
	
	NSInteger initialTabTag;
	NSView *initalView;
	
	NSDictionary *serverList;
	
	IBOutlet NSView *contentView;
	IBOutlet NSView *generalView;
	IBOutlet NSView *detailsView;
	IBOutlet NSView *onloginView;
	IBOutlet NSView *ignoresView;
	
	IBOutlet NSSegmentedControl *tabView;
	
	IBOutlet NSTextField* nameText;
	IBOutlet NSButton* autoReconnectCheck;
	IBOutlet NSButton* autoConnectCheck;
	
	IBOutlet NSComboBox* hostCombo;
	IBOutlet NSButton* sslCheck;
	IBOutlet NSTextField* portText;
	
	IBOutlet NSTextField* nickText;
	IBOutlet NSTextField* passwordText;
	IBOutlet NSTextField* usernameText;
	IBOutlet NSTextField* realNameText;
	IBOutlet NSTextField* nickPasswordText;
	IBOutlet NSTextField* altNicksText;
	
	IBOutlet NSTextField* sleepQuitMessageText;
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

@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, retain) IRCClientConfig* config;
@property (nonatomic, assign) IRCClient* client;
@property (nonatomic) NSInteger initialTabTag;
@property (nonatomic, retain) NSView *initalView;
@property (nonatomic, retain) NSView *contentView;
@property (nonatomic, retain) NSView *generalView;
@property (nonatomic, retain) NSView *detailsView;
@property (nonatomic, retain) NSView *onloginView;
@property (nonatomic, retain) NSView *ignoresView;
@property (nonatomic, retain) NSSegmentedControl *tabView;
@property (nonatomic, retain) NSTextField* nameText;
@property (nonatomic, retain) NSButton* autoReconnectCheck;
@property (nonatomic, retain) NSButton* autoConnectCheck;
@property (nonatomic, retain) NSComboBox* hostCombo;
@property (nonatomic, retain) NSButton* sslCheck;
@property (nonatomic, retain) NSTextField* portText;
@property (nonatomic, retain) NSTextField* nickText;
@property (nonatomic, retain) NSTextField* passwordText;
@property (nonatomic, retain) NSTextField* usernameText;
@property (nonatomic, retain) NSTextField* realNameText;
@property (nonatomic, retain) NSTextField* nickPasswordText;
@property (nonatomic, retain) NSTextField* altNicksText;
@property (nonatomic, retain) NSTextField* sleepQuitMessageText;
@property (nonatomic, retain) NSTextField* leavingCommentText;
@property (nonatomic, retain) NSTextField* userInfoText;
@property (nonatomic, retain) NSPopUpButton* encodingCombo;
@property (nonatomic, retain) NSPopUpButton* fallbackEncodingCombo;
@property (nonatomic, retain) NSPopUpButton* proxyCombo;
@property (nonatomic, retain) NSTextField* proxyHostText;
@property (nonatomic, retain) NSTextField* proxyPortText;
@property (nonatomic, retain) NSTextField* proxyUserText;
@property (nonatomic, retain) NSTextField* proxyPasswordText;
@property (nonatomic, retain) ListView* channelTable;
@property (nonatomic, retain) NSButton* addChannelButton;
@property (nonatomic, retain) NSButton* editChannelButton;
@property (nonatomic, retain) NSButton* deleteChannelButton;
@property (nonatomic, retain) NSTextView* loginCommandsText;
@property (nonatomic, retain) NSButton* invisibleCheck;
@property (nonatomic, retain) ListView* ignoreTable;
@property (nonatomic, retain) NSButton* addIgnoreButton;
@property (nonatomic, retain) NSButton* editIgnoreButton;
@property (nonatomic, retain) NSButton* deleteIgnoreButton;
@property (nonatomic, retain) ChannelSheet* channelSheet;
@property (nonatomic, retain) AddressBookSheet* ignoreSheet;

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