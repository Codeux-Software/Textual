// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 07, 2012

@class MenuController;

@interface LogPolicy : NSObject
@property (unsafe_unretained) MenuController *menuController;
@property (strong) NSMenu *menu;
@property (strong) NSMenu *urlMenu;
@property (strong) NSMenu *memberMenu;
@property (strong) NSMenu *chanMenu;
@property (strong) NSString *url;
@property (strong) NSString *nick;
@property (strong) NSString *chan;

- (void)channelDoubleClicked;
- (void)nicknameDoubleClicked;

@end