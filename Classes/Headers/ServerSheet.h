// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface ServerSheet : SheetBase
{
	NSInteger uid;
	
	IRCClient *client;
	IRCClientConfig *config;
	
	NSDictionary *serverList;
	
	IBOutlet NSView *contentView;
	IBOutlet NSView *generalView;
	IBOutlet NSView *detailsView;
	IBOutlet NSView *onloginView;
	IBOutlet NSView *ignoresView;
	
	IBOutlet NSSegmentedControl *tabView;
	
	IBOutlet NSTextField *nameText;
	IBOutlet NSButton *autoReconnectCheck;
	IBOutlet NSButton *autoConnectCheck;
	IBOutlet NSButton *bouncerModeCheck;
	
	IBOutlet NSComboBox *hostCombo;
	IBOutlet NSTextField *portText;
	IBOutlet NSButton *sslCheck;
	
	IBOutlet NSTextField *nickText;
	IBOutlet NSTextField *passwordText;
	IBOutlet NSTextField *usernameText;
	IBOutlet NSTextField *realNameText;
	IBOutlet NSTextField *nickPasswordText;
	IBOutlet NSTextField *altNicksText;
	
	IBOutlet NSTextField *sleepQuitMessageText;
	IBOutlet NSTextField *leavingCommentText;
	IBOutlet NSTextField *userInfoText;
	
	IBOutlet NSPopUpButton *encodingCombo;
	IBOutlet NSPopUpButton *fallbackEncodingCombo;
	
	IBOutlet NSPopUpButton *proxyCombo;
	IBOutlet NSTextField *proxyHostText;
	IBOutlet NSTextField *proxyPortText;
	IBOutlet NSTextField *proxyUserText;
	IBOutlet NSTextField *proxyPasswordText;
	
	IBOutlet ListView *channelTable;
	IBOutlet NSButton *addChannelButton;
	IBOutlet NSButton *editChannelButton;
	IBOutlet NSButton *deleteChannelButton;
	
	IBOutlet NSTextView *loginCommandsText;
	IBOutlet NSButton *invisibleCheck;
	
	IBOutlet ListView *ignoreTable;
	IBOutlet NSButton *addIgnoreButton;
	IBOutlet NSButton *editIgnoreButton;
	IBOutlet NSButton *deleteIgnoreButton;
	
	ChannelSheet *channelSheet;
	AddressBookSheet *ignoreSheet;
}

@property (assign) NSInteger uid;
@property (retain) IRCClientConfig *config;
@property (assign) IRCClient *client;
@property (retain) NSView *contentView;
@property (retain) NSView *generalView;
@property (retain) NSView *detailsView;
@property (retain) NSView *onloginView;
@property (retain) NSView *ignoresView;
@property (retain) NSSegmentedControl *tabView;
@property (retain) NSTextField *nameText;
@property (retain) NSButton *autoReconnectCheck;
@property (retain) NSButton *autoConnectCheck;
@property (retain) NSComboBox *hostCombo;
@property (retain) NSButton *sslCheck;
@property (retain) NSTextField *portText;
@property (retain) NSTextField *nickText;
@property (retain) NSTextField *passwordText;
@property (retain) NSTextField *usernameText;
@property (retain) NSTextField *realNameText;
@property (retain) NSTextField *nickPasswordText;
@property (retain) NSTextField *altNicksText;
@property (retain) NSTextField *sleepQuitMessageText;
@property (retain) NSTextField *leavingCommentText;
@property (retain) NSTextField *userInfoText;
@property (retain) NSPopUpButton *encodingCombo;
@property (retain) NSPopUpButton *fallbackEncodingCombo;
@property (retain) NSPopUpButton *proxyCombo;
@property (retain) NSTextField *proxyHostText;
@property (retain) NSTextField *proxyPortText;
@property (retain) NSTextField *proxyUserText;
@property (retain) NSTextField *proxyPasswordText;
@property (retain) ListView *channelTable;
@property (retain) NSButton *addChannelButton;
@property (retain) NSButton *editChannelButton;
@property (retain) NSButton *deleteChannelButton;
@property (retain) NSTextView *loginCommandsText;
@property (retain) NSButton *invisibleCheck;
@property (retain) ListView *ignoreTable;
@property (retain) NSButton *addIgnoreButton;
@property (retain) NSButton *editIgnoreButton;
@property (retain) NSButton *deleteIgnoreButton;
@property (retain) ChannelSheet *channelSheet;
@property (retain) AddressBookSheet *ignoreSheet;

- (void)startWithIgnoreTab:(NSString *)imask;

- (void)show;
- (void)showWithDefaultView:(NSView *)view andSegment:(NSInteger)segment;

- (void)close;

- (void)ok:(id)sender;
- (void)cancel:(id)sender;

- (void)hostComboChanged:(id)sender;

- (void)encodingChanged:(id)sender;
- (void)proxyChanged:(id)sender;
- (void)bouncerModeChanged:(id)sender;

- (void)addChannel:(id)sender;
- (void)editChannel:(id)sender;
- (void)deleteChannel:(id)sender;

- (void)addIgnore:(id)sender;
- (void)editIgnore:(id)sender;
- (void)deleteIgnore:(id)sender;

- (void)onMenuBarItemChanged:(id)sender;
@end

@interface NSObject (ServerSheetDelegate)
- (void)ServerSheetOnOK:(ServerSheet *)sender;
- (void)ServerSheetWillClose:(ServerSheet *)sender;
@end