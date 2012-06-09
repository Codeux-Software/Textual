// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 08, 2012

@interface WelcomeSheet : SheetBase
@property (nonatomic, strong) NSMutableArray *channels;
@property (nonatomic, strong) NSTextField *nickText;
@property (nonatomic, strong) NSTextField *hostCombo;
@property (nonatomic, strong) ListView *channelTable;
@property (nonatomic, strong) NSButton *autoConnectCheck;
@property (nonatomic, strong) NSButton *addChannelButton;
@property (nonatomic, strong) NSButton *deleteChannelButton;

- (void)show;
- (void)close;

- (void)onOK:(id)sender;
- (void)onCancel:(id)sender;
- (void)onAddChannel:(id)sender;
- (void)onDeleteChannel:(id)sender;

- (void)onHostComboChanged:(id)sender;
@end

@interface NSObject (WelcomeSheetDelegate)
- (void)WelcomeSheet:(WelcomeSheet *)sender onOK:(NSDictionary *)config;
- (void)WelcomeSheetWillClose:(WelcomeSheet *)sender;
@end