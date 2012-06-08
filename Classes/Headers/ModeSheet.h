// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface ModeSheet : SheetBase
{
	IRCChannelMode *__weak mode;
	
	NSString *channelName;
	
	NSInteger uid;
	NSInteger cid;
	
	IBOutlet NSButton *sCheck;
	IBOutlet NSButton *pCheck;
	IBOutlet NSButton *nCheck;
	IBOutlet NSButton *tCheck;
	IBOutlet NSButton *iCheck;
	IBOutlet NSButton *mCheck;
	IBOutlet NSButton *kCheck;
	IBOutlet NSButton *lCheck;
	
	IBOutlet NSTextField *kText;
	IBOutlet NSTextField *lText;
}

@property (weak) IRCChannelMode *mode;
@property (strong) NSString *channelName;
@property (assign) NSInteger uid;
@property (assign) NSInteger cid;
@property (strong) NSButton *sCheck;
@property (strong) NSButton *pCheck;
@property (strong) NSButton *nCheck;
@property (strong) NSButton *tCheck;
@property (strong) NSButton *iCheck;
@property (strong) NSButton *mCheck;
@property (strong) NSButton *kCheck;
@property (strong) NSButton *lCheck;
@property (strong) NSTextField *kText;
@property (strong) NSTextField *lText;

- (void)start;
- (void)onChangeCheck:(id)sender;
@end

@interface NSObject (ModeSheetDelegate)
- (void)modeSheetOnOK:(ModeSheet *)sender;
- (void)modeSheetWillClose:(ModeSheet *)sender;
@end