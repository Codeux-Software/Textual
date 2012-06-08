// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface ServerSheet : SheetBase
{
	NSInteger uid;
	
	IRCClient *__weak client;
	IRCClientConfig *config;
	
	NSDictionary *serverList;
	NSMutableArray *tabViewList;
	
	IBOutlet NSView *contentView;
	IBOutlet NSView *generalView;
	IBOutlet NSView *identityView;
	IBOutlet NSView *messagesView;
	IBOutlet NSView *encodingView;
	IBOutlet NSView *autojoinView;
	IBOutlet NSView *ignoresView;
	IBOutlet NSView *commandsView;
    IBOutlet NSView *floodControlView;
    IBOutlet NSView *floodControlToolView;
	IBOutlet NSView *proxyServerView;
    
    IBOutlet NSButton *outgoingFloodControl;
    IBOutlet NSSlider *floodControlMessageCount;
    IBOutlet NSSlider *floodControlDelayTimer;
	
	IBOutlet ListView *tabView;
	
	IBOutlet NSTextField *nameText;
	IBOutlet NSButton *autoReconnectCheck;
	IBOutlet NSButton *autoConnectCheck;
	IBOutlet NSButton *bouncerModeCheck;
    IBOutlet NSButton *prefersIPv6Check;
	
	IBOutlet NSComboBox *hostCombo;
	IBOutlet NSTextField *portText;
	IBOutlet NSButton *sslCheck;
	
	IBOutlet NSTextField *nickText;
	IBOutlet NSTextField *passwordText;
	IBOutlet NSTextField *usernameText;
	IBOutlet NSTextField *realNameText;
	IBOutlet NSTextField *nickPasswordText;
	IBOutlet NSTextField *altNicksText;
	
	IBOutlet NSTextView *sleepQuitMessageText;
	IBOutlet NSTextView *leavingCommentText;
	
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
	IBOutlet NSMenu *addIgnoreMenu;
	
	ChannelSheet *channelSheet;
	AddressBookSheet *ignoreSheet;
}

@property (assign) NSInteger uid;
@property (strong) IRCClientConfig *config;
@property (weak) IRCClient *client;
@property (strong) NSView *contentView;
@property (strong) NSView *generalView;
@property (strong) NSView *identityView;
@property (strong) NSView *messagesView;
@property (strong) NSView *encodingView;
@property (strong) NSView *autojoinView;
@property (strong) NSView *ignoresView;
@property (strong) NSView *commandsView;
@property (strong) NSView *floodControlView;
@property (strong) NSView *floodControlToolView;
@property (strong) NSView *proxyServerView;
@property (strong) NSButton *outgoingFloodControl;
@property (strong) NSSlider *floodControlMessageCount;
@property (strong) NSSlider *floodControlDelayTimer;
@property (strong) ListView *tabView;
@property (strong) NSTextField *nameText;
@property (strong) NSButton *prefersIPv6Check;
@property (strong) NSButton *autoReconnectCheck;
@property (strong) NSButton *autoConnectCheck;
@property (strong) NSComboBox *hostCombo;
@property (strong) NSButton *sslCheck;
@property (strong) NSTextField *portText;
@property (strong) NSTextField *nickText;
@property (strong) NSTextField *passwordText;
@property (strong) NSTextField *usernameText;
@property (strong) NSTextField *realNameText;
@property (strong) NSTextField *nickPasswordText;
@property (strong) NSTextField *altNicksText;
@property (strong) NSTextView *sleepQuitMessageText;
@property (strong) NSTextView *leavingCommentText;
@property (strong) NSPopUpButton *encodingCombo;
@property (strong) NSPopUpButton *fallbackEncodingCombo;
@property (strong) NSPopUpButton *proxyCombo;
@property (strong) NSTextField *proxyHostText;
@property (strong) NSTextField *proxyPortText;
@property (strong) NSTextField *proxyUserText;
@property (strong) NSTextField *proxyPasswordText;
@property (strong) ListView *channelTable;
@property (strong) NSButton *addChannelButton;
@property (strong) NSButton *editChannelButton;
@property (strong) NSButton *deleteChannelButton;
@property (strong) NSTextView *loginCommandsText;
@property (strong) NSButton *invisibleCheck;
@property (strong) ListView *ignoreTable;
@property (strong) NSButton *addIgnoreButton;
@property (strong) NSButton *editIgnoreButton;
@property (strong) NSButton *deleteIgnoreButton;
@property (strong) NSMenu *addIgnoreMenu;
@property (strong) ChannelSheet *channelSheet;
@property (strong) AddressBookSheet *ignoreSheet;

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
- (void)floodControlChanged:(id)sender;

- (void)addChannel:(id)sender;
- (void)editChannel:(id)sender;
- (void)deleteChannel:(id)sender;

- (void)addIgnore:(id)sender;
- (void)editIgnore:(id)sender;
- (void)deleteIgnore:(id)sender;
- (void)showAddIgnoreMenu:(id)sender;
@end

@interface NSObject (ServerSheetDelegate)
- (void)ServerSheetOnOK:(ServerSheet *)sender;
- (void)ServerSheetWillClose:(ServerSheet *)sender;
@end
