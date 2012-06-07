// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@class MenuController;

@interface LogPolicy : NSObject
{
	MenuController *__unsafe_unretained menuController;
	
	NSMenu *menu;
	NSMenu *urlMenu;
	NSMenu *addrMenu;
	NSMenu *memberMenu;
	NSMenu *chanMenu;
	
	NSString *url;
	NSString *addr;
	NSString *nick;
	NSString *chan;
}

@property (nonatomic, unsafe_unretained) id menuController;
@property (nonatomic, strong) NSMenu *menu;
@property (nonatomic, strong) NSMenu *urlMenu;
@property (nonatomic, strong) NSMenu *addrMenu;
@property (nonatomic, strong) NSMenu *memberMenu;
@property (nonatomic, strong) NSMenu *chanMenu;
@property (nonatomic, strong) NSString *url;
@property (nonatomic, strong) NSString *addr;
@property (nonatomic, strong) NSString *nick;
@property (nonatomic, strong) NSString *chan;

- (void)channelDoubleClicked;
- (void)nicknameDoubleClicked;

@end