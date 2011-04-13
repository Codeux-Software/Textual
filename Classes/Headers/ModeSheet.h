// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface ModeSheet : SheetBase
{
	IRCChannelMode *mode;
	
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

@property (assign) IRCChannelMode *mode;
@property (retain) NSString *channelName;
@property (assign) NSInteger uid;
@property (assign) NSInteger cid;
@property (retain) NSButton *sCheck;
@property (retain) NSButton *pCheck;
@property (retain) NSButton *nCheck;
@property (retain) NSButton *tCheck;
@property (retain) NSButton *iCheck;
@property (retain) NSButton *mCheck;
@property (retain) NSButton *kCheck;
@property (retain) NSButton *lCheck;
@property (retain) NSTextField *kText;
@property (retain) NSTextField *lText;

- (void)start;
- (void)onChangeCheck:(id)sender;
@end

@interface NSObject (ModeSheetDelegate)
- (void)modeSheetOnOK:(ModeSheet *)sender;
- (void)modeSheetWillClose:(ModeSheet *)sender;
@end