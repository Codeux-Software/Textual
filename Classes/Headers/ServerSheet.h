// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface ServerSheet : SheetBase
{
	NSInteger uid;
	
	IRCClient *client;
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
    IBOutlet NSView *socketsView;
    IBOutlet NSView *floodControlView;
    IBOutlet NSView *floodControlToolView;
	IBOutlet NSView *proxyServerView;
    
    IBOutlet NSButton *incomingFloodControl;
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
    IBOutlet NSButton *saslCheck;
	
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
    
    IBOutlet NSTextField *pongInterval;
    IBOutlet NSTextField *timeoutInterval;
	
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

@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, retain) IRCClientConfig *config;
@property (nonatomic, assign) IRCClient *client;
@property (nonatomic, retain) NSView *contentView;
@property (nonatomic, retain) NSView *generalView;
@property (nonatomic, retain) NSView *identityView;
@property (nonatomic, retain) NSView *messagesView;
@property (nonatomic, retain) NSView *encodingView;
@property (nonatomic, retain) NSView *autojoinView;
@property (nonatomic, retain) NSView *ignoresView;
@property (nonatomic, retain) NSView *commandsView;
@property (nonatomic, retain) NSView *socketsView;
@property (nonatomic, retain) NSView *floodControlView;
@property (nonatomic, retain) NSView *floodControlToolView;
@property (nonatomic, retain) NSView *proxyServerView;
@property (nonatomic, retain) NSButton *incomingFloodControl;
@property (nonatomic, retain) NSButton *outgoingFloodControl;
@property (nonatomic, retain) NSSlider *floodControlMessageCount;
@property (nonatomic, retain) NSSlider *floodControlDelayTimer;
@property (nonatomic, retain) ListView *tabView;
@property (nonatomic, retain) NSTextField *nameText;
@property (nonatomic, retain) NSButton *prefersIPv6Check;
@property (nonatomic, retain) NSButton *autoReconnectCheck;
@property (nonatomic, retain) NSButton *autoConnectCheck;
@property (nonatomic, retain) NSComboBox *hostCombo;
@property (nonatomic, retain) NSButton *sslCheck;
@property (nonatomic, retain) NSButton *saslCheck;
@property (nonatomic, retain) NSTextField *portText;
@property (nonatomic, retain) NSTextField *nickText;
@property (nonatomic, retain) NSTextField *passwordText;
@property (nonatomic, retain) NSTextField *usernameText;
@property (nonatomic, retain) NSTextField *realNameText;
@property (nonatomic, retain) NSTextField *nickPasswordText;
@property (nonatomic, retain) NSTextField *altNicksText;
@property (nonatomic, retain) NSTextView *sleepQuitMessageText;
@property (nonatomic, retain) NSTextView *leavingCommentText;
@property (nonatomic, retain) NSPopUpButton *encodingCombo;
@property (nonatomic, retain) NSPopUpButton *fallbackEncodingCombo;
@property (nonatomic, retain) NSPopUpButton *proxyCombo;
@property (nonatomic, retain) NSTextField *proxyHostText;
@property (nonatomic, retain) NSTextField *proxyPortText;
@property (nonatomic, retain) NSTextField *proxyUserText;
@property (nonatomic, retain) NSTextField *proxyPasswordText;
@property (nonatomic, retain) NSTextField *pongInterval;
@property (nonatomic, retain) NSTextField *timeoutInterval;
@property (nonatomic, retain) ListView *channelTable;
@property (nonatomic, retain) NSButton *addChannelButton;
@property (nonatomic, retain) NSButton *editChannelButton;
@property (nonatomic, retain) NSButton *deleteChannelButton;
@property (nonatomic, retain) NSTextView *loginCommandsText;
@property (nonatomic, retain) NSButton *invisibleCheck;
@property (nonatomic, retain) ListView *ignoreTable;
@property (nonatomic, retain) NSButton *addIgnoreButton;
@property (nonatomic, retain) NSButton *editIgnoreButton;
@property (nonatomic, retain) NSButton *deleteIgnoreButton;
@property (nonatomic, retain) NSMenu *addIgnoreMenu;
@property (nonatomic, retain) ChannelSheet *channelSheet;
@property (nonatomic, retain) AddressBookSheet *ignoreSheet;

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