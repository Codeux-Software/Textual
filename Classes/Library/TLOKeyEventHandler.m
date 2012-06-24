// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

#import "TextualApplication.h"

#import <objc/objc-runtime.h>

@implementation TLOKeyEventHandler

- (id)init
{
	if ((self = [super init])) {
		self.codeHandlerMap			= [NSMutableDictionary new];
		self.characterHandlerMap	= [NSMutableDictionary new];
	}
	
	return self;
}

- (void)registerSelector:(SEL)selector key:(NSInteger)code modifiers:(NSUInteger)mods
{
	NSNumber *modsKey = @(mods);
	
	NSMutableDictionary *map = (self.codeHandlerMap)[modsKey];
	
	if (NSObjectIsEmpty(map)) {
		map = [NSMutableDictionary dictionary];
		
		(self.codeHandlerMap)[modsKey] = map;
	}
	
	map[@(code)] = NSStringFromSelector(selector);
}

- (void)registerSelector:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods
{
	NSNumber *modsKey = @(mods);
	
	NSMutableDictionary *map = (self.characterHandlerMap)[modsKey];
	
	if (NSObjectIsEmpty(map)) {
		map = [NSMutableDictionary dictionary];
		
		(self.characterHandlerMap)[modsKey] = map;
	}
	
	map[NSNumberWithInteger(c)] = NSStringFromSelector(selector);
}

- (void)registerSelector:(SEL)selector characters:(NSRange)characterRange modifiers:(NSUInteger)mods
{
	NSNumber *modsKey = @(mods);
	
	NSMutableDictionary *map = (self.characterHandlerMap)[modsKey];
	
	if (NSObjectIsEmpty(map)) {
		map = [NSMutableDictionary dictionary];
		
		(self.characterHandlerMap)[modsKey] = map;
	}
	
	NSInteger from = characterRange.location;
	NSInteger to = NSMaxRange(characterRange);
	
	for (NSInteger i = from; i < to; ++i) {
		NSNumber *charKey = @(i);
		
		map[charKey] = NSStringFromSelector(selector);
	}
}

- (BOOL)processKeyEvent:(NSEvent *)e
{
	NSInputManager *im = [NSInputManager currentInputManager];
	if (im && [im markedRange].length > 0) return NO;
	
	NSUInteger m;

	m  = [e modifierFlags];
	m &= (NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask);
	
	NSNumber *modsKey = @(m);
	
	NSMutableDictionary *codeMap = (self.codeHandlerMap)[modsKey];
	
	if (codeMap) {
		NSString *selectorName = codeMap[NSNumberWithInteger([e keyCode])];

		if (selectorName) {
			objc_msgSend(self.target, NSSelectorFromString(selectorName), e);
			
			return YES;
		}
	}
	
	NSMutableDictionary *characterMap = (self.characterHandlerMap)[modsKey];
	
	if (characterMap) {
		NSString *str = [[e charactersIgnoringModifiers] lowercaseString];
		
		if (NSObjectIsNotEmpty(str)) {
			NSString *selectorName = characterMap[NSNumberWithInteger([str characterAtIndex:0])];
			
			if (selectorName) {
				objc_msgSend(self.target, NSSelectorFromString(selectorName), e);
				
				return YES;
			}
		}
	}
	
	return NO;
}

@end