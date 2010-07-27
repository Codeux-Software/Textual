// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
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
	IBOutlet NSButton* autoJoinCheck;
	IBOutlet NSButton* growlCheck;
}

@property (assign) NSInteger uid;
@property (assign) NSInteger cid;
@property (retain) IRCChannelConfig* config;
@property (retain) NSTextField* nameText;
@property (retain) NSTextField* passwordText;
@property (retain) NSTextField* modeText;
@property (retain) NSTextField* topicText;
@property (retain) NSButton* autoJoinCheck;
@property (retain) NSButton* growlCheck;

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