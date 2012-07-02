// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface TDCServerSheet : TDCSheetBase
@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, weak) IRCClient *client;
@property (nonatomic, strong) IRCClientConfig *config;
@property (nonatomic, strong) NSDictionary *serverList;
@property (nonatomic, strong) NSMutableArray *tabViewList;
@property (nonatomic, strong) NSView *contentView;
@property (nonatomic, strong) NSView *generalView;
@property (nonatomic, strong) NSView *identityView;
@property (nonatomic, strong) NSView *messagesView;
@property (nonatomic, strong) NSView *encodingView;
@property (nonatomic, strong) NSView *autojoinView;
@property (nonatomic, strong) NSView *ignoresView;
@property (nonatomic, strong) NSView *commandsView;
@property (nonatomic, strong) NSView *floodControlView;
@property (nonatomic, strong) NSView *floodControlToolView;
@property (nonatomic, strong) NSView *proxyServerView;
@property (nonatomic, strong) NSButton *outgoingFloodControl;
@property (nonatomic, strong) NSSlider *floodControlMessageCount;
@property (nonatomic, strong) NSSlider *floodControlDelayTimer;
@property (nonatomic, strong) TVCListView *tabView;
@property (nonatomic, strong) NSTextField *nameText;
@property (nonatomic, strong) NSButton *prefersIPv6Check;
@property (nonatomic, strong) NSButton *autoReconnectCheck;
@property (nonatomic, strong) NSButton *autoConnectCheck;
@property (nonatomic, strong) NSButton *bouncerModeCheck;
@property (nonatomic, strong) NSComboBox *hostCombo;
@property (nonatomic, strong) NSButton *sslCheck;
@property (nonatomic, strong) NSTextField *portText;
@property (nonatomic, strong) NSTextField *nickText;
@property (nonatomic, strong) NSTextField *passwordText;
@property (nonatomic, strong) NSTextField *usernameText;
@property (nonatomic, strong) NSTextField *realNameText;
@property (nonatomic, strong) NSTextField *nickPasswordText;
@property (nonatomic, strong) NSTextField *altNicksText;
@property (nonatomic, strong) NSTextView *sleepQuitMessageText;
@property (nonatomic, strong) NSTextView *leavingCommentText;
@property (nonatomic, strong) NSPopUpButton *encodingCombo;
@property (nonatomic, strong) NSPopUpButton *fallbackEncodingCombo;
@property (nonatomic, strong) NSPopUpButton *proxyCombo;
@property (nonatomic, strong) NSTextField *proxyHostText;
@property (nonatomic, strong) NSTextField *proxyPortText;
@property (nonatomic, strong) NSTextField *proxyUserText;
@property (nonatomic, strong) NSTextField *proxyPasswordText;
@property (nonatomic, strong) TVCListView *channelTable;
@property (nonatomic, strong) NSButton *addChannelButton;
@property (nonatomic, strong) NSButton *editChannelButton;
@property (nonatomic, strong) NSButton *deleteChannelButton;
@property (nonatomic, strong) NSTextView *loginCommandsText;
@property (nonatomic, strong) NSButton *invisibleCheck;
@property (nonatomic, strong) TVCListView *ignoreTable;
@property (nonatomic, strong) NSButton *addIgnoreButton;
@property (nonatomic, strong) NSButton *editIgnoreButton;
@property (nonatomic, strong) NSButton *deleteIgnoreButton;
@property (nonatomic, strong) NSMenu *addIgnoreMenu;
@property (nonatomic, strong) TDChannelSheet *channelSheet;
@property (nonatomic, strong) TDCAddressBookSheet *ignoreSheet;

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

@interface NSObject (TXServerSheetDelegate)
- (void)serverSheetOnOK:(TDCServerSheet *)sender;
- (void)serverSheetWillClose:(TDCServerSheet *)sender;
@end
