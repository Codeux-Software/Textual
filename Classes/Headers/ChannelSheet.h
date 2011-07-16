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

@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, assign) NSInteger cid;
@property (nonatomic, retain) NSView *contentView;
@property (nonatomic, retain) NSView *generalView;
@property (nonatomic, retain) NSView *encryptView;
@property (nonatomic, retain) NSView *defaultsView;
@property (nonatomic, retain) IRCChannelConfig *config;
@property (nonatomic, retain) NSTextField *nameText;
@property (nonatomic, retain) NSTextField *passwordText;
@property (nonatomic, retain) NSTextField *modeText;
@property (nonatomic, retain) NSTextField *topicText;
@property (nonatomic, retain) NSTextField *encryptKeyText;
@property (nonatomic, retain) NSSegmentedControl *tabView;
@property (nonatomic, retain) NSButton *autoJoinCheck;
@property (nonatomic, retain) NSButton *ihighlights;
@property (nonatomic, retain) NSButton *growlCheck;
@property (nonatomic, retain) NSButton *inlineImagesCheck;
@property (nonatomic, retain) NSButton *JPQActivityCheck;

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