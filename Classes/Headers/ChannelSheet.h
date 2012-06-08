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
    IBOutlet NSView *defaultsView;
 	
	IBOutlet NSTextField *nameText;
	IBOutlet NSTextField *passwordText;
	IBOutlet NSTextField *modeText;
	IBOutlet NSTextField *topicText;
	IBOutlet NSTextField *encryptKeyText;
	
	IBOutlet NSSegmentedControl *tabView;
	
    IBOutlet NSButton *ihighlights;
	IBOutlet NSButton *autoJoinCheck;
	IBOutlet NSButton *growlCheck;
    IBOutlet NSButton *inlineImagesCheck;
    IBOutlet NSButton *JPQActivityCheck;
}

@property (assign) NSInteger uid;
@property (assign) NSInteger cid;
@property (strong) NSView *contentView;
@property (strong) NSView *generalView;
@property (strong) NSView *encryptView;
@property (strong) NSView *defaultsView;
@property (strong) IRCChannelConfig *config;
@property (strong) NSTextField *nameText;
@property (strong) NSTextField *passwordText;
@property (strong) NSTextField *modeText;
@property (strong) NSTextField *topicText;
@property (strong) NSTextField *encryptKeyText;
@property (strong) NSSegmentedControl *tabView;
@property (strong) NSButton *autoJoinCheck;
@property (strong) NSButton *ihighlights;
@property (strong) NSButton *growlCheck;
@property (strong) NSButton *inlineImagesCheck;
@property (strong) NSButton *JPQActivityCheck;

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