// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Foundation/Foundation.h>
#import "IRCChannelConfig.h"
#import "SheetBase.h"

@interface ChannelSheet : SheetBase
{
	NSInteger uid;
	NSInteger cid;
	IRCChannelConfig* config;
	
	IBOutlet NSTextField* nameText;
	IBOutlet NSTextField* passwordText;
	IBOutlet NSTextField* modeText;
	IBOutlet NSTextField* topicText;
    IBOutlet NSButton* ihighlights;
	IBOutlet NSButton* autoJoinCheck;
	IBOutlet NSButton* growlCheck;
}

@property (nonatomic, assign) NSInteger uid;
@property (nonatomic, assign) NSInteger cid;
@property (nonatomic, retain) IRCChannelConfig* config;
@property (nonatomic, retain) NSTextField* nameText;
@property (nonatomic, retain) NSTextField* passwordText;
@property (nonatomic, retain) NSTextField* modeText;
@property (nonatomic, retain) NSTextField* topicText;
@property (nonatomic, retain) NSButton* autoJoinCheck;
@property (nonatomic, retain) NSButton* ihighlights;
@property (nonatomic, retain) NSButton* growlCheck;

- (void)start;
- (void)show;
- (void)close;

- (void)ok:(id)sender;
- (void)cancel:(id)sender;
@end

@interface NSObject (ChannelSheetDelegate)
- (void)ChannelSheetOnOK:(ChannelSheet*)sender;
- (void)ChannelSheetWillClose:(ChannelSheet*)sender;
@end