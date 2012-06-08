// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface WelcomeSheet : SheetBase
{
	NSMutableArray *channels;
	
	IBOutlet NSTextField *nickText;
	IBOutlet NSTextField *hostCombo;
	
	IBOutlet ListView *channelTable;
	
	IBOutlet NSButton *autoConnectCheck;
	IBOutlet NSButton *addChannelButton;
	IBOutlet NSButton *deleteChannelButton;
}

@property (strong) NSMutableArray *channels;
@property (strong) NSTextField *nickText;
@property (strong) NSTextField *hostCombo;
@property (strong) ListView *channelTable;
@property (strong) NSButton *autoConnectCheck;
@property (strong) NSButton *addChannelButton;
@property (strong) NSButton *deleteChannelButton;

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