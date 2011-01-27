// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#define KEY_RETURN		0x24
#define KEY_TAB			0x30
#define KEY_SPACE		0x31
#define KEY_BACKSPACE	0x33
#define KEY_ESCAPE		0x35
#define KEY_ENTER		0x4C
#define KEY_HOME		0x73
#define KEY_PAGE_UP		0x74
#define KEY_DELETE		0x75
#define KEY_END			0x77
#define KEY_PAGE_DOWN	0x79
#define KEY_LEFT		0x7B
#define KEY_RIGHT		0x7C
#define KEY_DOWN		0x7D
#define KEY_UP			0x7E

@interface KeyEventHandler : NSObject
{
	id target;
	
	NSMutableDictionary *codeHandlerMap;
	NSMutableDictionary *characterHandlerMap;
}

@property (nonatomic, assign) id target;
@property (nonatomic, retain) NSMutableDictionary *codeHandlerMap;
@property (nonatomic, retain) NSMutableDictionary *characterHandlerMap;

- (void)registerSelector:(SEL)selector key:(NSInteger)code modifiers:(NSUInteger)mods;
- (void)registerSelector:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods;
- (void)registerSelector:(SEL)selector characters:(NSRange)characterRange modifiers:(NSUInteger)mods;

- (BOOL)processKeyEvent:(NSEvent *)e;
@end