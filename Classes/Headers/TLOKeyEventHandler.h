// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

#define TXKeyReturnCode			0x24
#define TXKeyTabCode			0x30
#define TXKeySpacebarCode		0x31
#define TXKeyBackspaceCode		0x33
#define TXKeyEscapeCode			0x35
#define TXKeyEnterCode			0x4C
#define TXKeyHomeCode			0x73
#define TXKeyPageUpCode			0x74
#define TXKeyDeleteCode			0x75
#define TXKeyEndCode			0x77
#define TXKeyPageDownCode		0x79
#define TXKeyLeftArrowCode		0x7B
#define TXKeyRightArrowCode		0x7C
#define TXKeyDownArrowCode		0x7D
#define TXKeyUpArrowCode		0x7E

@interface TLOKeyEventHandler : NSObject
@property (nonatomic, unsafe_unretained) id target;
@property (nonatomic, strong) NSMutableDictionary *codeHandlerMap;
@property (nonatomic, strong) NSMutableDictionary *characterHandlerMap;

- (void)registerSelector:(SEL)selector key:(NSInteger)code modifiers:(NSUInteger)mods;
- (void)registerSelector:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods;
- (void)registerSelector:(SEL)selector characters:(NSRange)characterRange modifiers:(NSUInteger)mods;

- (BOOL)processKeyEvent:(NSEvent *)e;
@end