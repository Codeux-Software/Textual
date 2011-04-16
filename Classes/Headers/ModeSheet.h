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

@property (nonatomic, assign) IRCChannelMode *mode;
@property (nonatomic, retain) NSString *channelName;
@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, assign) NSInteger cid;
@property (nonatomic, retain) NSButton *sCheck;
@property (nonatomic, retain) NSButton *pCheck;
@property (nonatomic, retain) NSButton *nCheck;
@property (nonatomic, retain) NSButton *tCheck;
@property (nonatomic, retain) NSButton *iCheck;
@property (nonatomic, retain) NSButton *mCheck;
@property (nonatomic, retain) NSButton *kCheck;
@property (nonatomic, retain) NSButton *lCheck;
@property (nonatomic, retain) NSTextField *kText;
@property (nonatomic, retain) NSTextField *lText;

- (void)start;
- (void)onChangeCheck:(id)sender;
@end

@interface NSObject (ModeSheetDelegate)
- (void)modeSheetOnOK:(ModeSheet *)sender;
- (void)modeSheetWillClose:(ModeSheet *)sender;
@end