// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@interface TDChannelSheet : TDCSheetBase
@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, assign) NSInteger cid;
@property (nonatomic, strong) NSView *contentView;
@property (nonatomic, strong) NSView *generalView;
@property (nonatomic, strong) NSView *encryptView;
@property (nonatomic, strong) NSView *defaultsView;
@property (nonatomic, strong) IRCChannelConfig *config;
@property (nonatomic, strong) NSTextField *nameText;
@property (nonatomic, strong) NSTextField *passwordText;
@property (nonatomic, strong) NSTextField *modeText;
@property (nonatomic, strong) NSTextField *topicText;
@property (nonatomic, strong) NSTextField *encryptKeyText;
@property (nonatomic, strong) NSSegmentedControl *tabView;
@property (nonatomic, strong) NSButton *autoJoinCheck;
@property (nonatomic, strong) NSButton *ihighlights;
@property (nonatomic, strong) NSButton *growlCheck;
@property (nonatomic, strong) NSButton *inlineImagesCheck;
@property (nonatomic, strong) NSButton *JPQActivityCheck;

- (void)start;
- (void)show;
- (void)close;

- (void)ok:(id)sender;
- (void)cancel:(id)sender;

- (void)onMenuBarItemChanged:(id)sender;
@end

@interface NSObject (TXChannelSheetDelegate)
- (void)channelSheetOnOK:(TDChannelSheet *)sender;
- (void)channelSheetWillClose:(TDChannelSheet *)sender;
@end