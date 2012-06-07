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

@property (nonatomic, weak) IRCChannelMode *mode;
@property (nonatomic, strong) NSString *channelName;
@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, assign) NSInteger cid;
@property (nonatomic, strong) NSButton *sCheck;
@property (nonatomic, strong) NSButton *pCheck;
@property (nonatomic, strong) NSButton *nCheck;
@property (nonatomic, strong) NSButton *tCheck;
@property (nonatomic, strong) NSButton *iCheck;
@property (nonatomic, strong) NSButton *mCheck;
@property (nonatomic, strong) NSButton *kCheck;
@property (nonatomic, strong) NSButton *lCheck;
@property (nonatomic, strong) NSTextField *kText;
@property (nonatomic, strong) NSTextField *lText;

- (void)start;
- (void)onChangeCheck:(id)sender;
@end

@interface NSObject (ModeSheetDelegate)
- (void)modeSheetOnOK:(ModeSheet *)sender;
- (void)modeSheetWillClose:(ModeSheet *)sender;
@end