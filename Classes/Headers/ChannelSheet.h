// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface ChannelSheet : SheetBase
{
	NSInteger uid;
	NSInteger cid;
	
	IRCChannelConfig *config;
	
	IBOutlet NSView *contentView;
	IBOutlet NSView *generalView;
	IBOutlet NSView *encryptView;
 	
	IBOutlet NSTextField *nameText;
	IBOutlet NSTextField *passwordText;
	IBOutlet NSTextField *modeText;
	IBOutlet NSTextField *topicText;
	IBOutlet NSTextField *encryptKeyText;
	
	IBOutlet NSSegmentedControl *tabView;
	
    IBOutlet NSButton *ihighlights;
	IBOutlet NSButton *autoJoinCheck;
	IBOutlet NSButton *growlCheck;
}

@property (assign) NSInteger uid;
@property (assign) NSInteger cid;
@property (retain) NSView *contentView;
@property (retain) NSView *generalView;
@property (retain) NSView *encryptView;
@property (retain) IRCChannelConfig *config;
@property (retain) NSTextField *nameText;
@property (retain) NSTextField *passwordText;
@property (retain) NSTextField *modeText;
@property (retain) NSTextField *topicText;
@property (retain) NSTextField *encryptKeyText;
@property (retain) NSSegmentedControl *tabView;
@property (retain) NSButton *autoJoinCheck;
@property (retain) NSButton *ihighlights;
@property (retain) NSButton *growlCheck;

- (void)start;
- (void)show;
- (void)close;

- (void)ok:(id)sender;
- (void)cancel:(id)sender;

- (void)onMenuBarItemChanged:(id)sender;
@end

@interface NSObject (ChannelSheetDelegate)
- (void)ChannelSheetOnOK:(ChannelSheet *)sender;
- (void)ChannelSheetWillClose:(ChannelSheet *)sender;
@end