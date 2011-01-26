// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation KeyEventHandler

@synthesize target;
@synthesize codeHandlerMap;
@synthesize characterHandlerMap;

- (id)init
{
	if ((self = [super init])) {
		codeHandlerMap = [NSMutableDictionary new];
		characterHandlerMap = [NSMutableDictionary new];
	}
	
	return self;
}

- (void)dealloc
{
	[codeHandlerMap release];
	[characterHandlerMap release];
	
	[super dealloc];
}

- (void)registerSelector:(SEL)selector key:(NSInteger)code modifiers:(NSUInteger)mods
{
	NSNumber *modsKey = [NSNumber numberWithUnsignedInteger:mods];
	NSMutableDictionary *map = [codeHandlerMap objectForKey:modsKey];
	
	if (NSObjectIsEmpty(map)) {
		map = [NSMutableDictionary dictionary];
		
		[codeHandlerMap setObject:map forKey:modsKey];
	}
	
	[map setObject:NSStringFromSelector(selector) forKey:[NSNumber numberWithInteger:code]];
}

- (void)registerSelector:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods
{
	NSNumber *modsKey = [NSNumber numberWithUnsignedInteger:mods];
	NSMutableDictionary *map = [characterHandlerMap objectForKey:modsKey];
	
	if (NSObjectIsEmpty(map)) {
		map = [NSMutableDictionary dictionary];
		
		[characterHandlerMap setObject:map forKey:modsKey];
	}
	
	[map setObject:NSStringFromSelector(selector) forKey:[NSNumber numberWithInteger:c]];
}

- (void)registerSelector:(SEL)selector characters:(NSRange)characterRange modifiers:(NSUInteger)mods
{
	NSNumber *modsKey = [NSNumber numberWithUnsignedInteger:mods];
	NSMutableDictionary *map = [characterHandlerMap objectForKey:modsKey];
	
	if (NSObjectIsEmpty(map)) {
		map = [NSMutableDictionary dictionary];
		
		[characterHandlerMap setObject:map forKey:modsKey];
	}
	
	NSInteger from = characterRange.location;
	NSInteger to = NSMaxRange(characterRange);
	
	for (NSInteger i = from; i < to; ++i) {
		NSNumber *charKey = [NSNumber numberWithInteger:i];
		
		[map setObject:NSStringFromSelector(selector) forKey:charKey];
	}
}

- (BOOL)processKeyEvent:(NSEvent *)e
{
	NSInputManager *im = [NSInputManager currentInputManager];
	if (im && [im markedRange].length > 0) return NO;
	
	NSUInteger m = [e modifierFlags];
	m &= (NSShiftKeyMask | NSControlKeyMask | NSAlternateKeyMask | NSCommandKeyMask);
	NSNumber *modsKey = [NSNumber numberWithUnsignedInteger:m];
	
	NSMutableDictionary *codeMap = [codeHandlerMap objectForKey:modsKey];
	
	if (codeMap) {
		NSString *selectorName = [codeMap objectForKey:[NSNumber numberWithInteger:[e keyCode]]];
		
		if (selectorName) {
			[target performSelector:NSSelectorFromString(selectorName) withObject:e];
			
			return YES;
		}
	}
	
	NSMutableDictionary *characterMap = [characterHandlerMap objectForKey:modsKey];
	
	if (characterMap) {
		NSString *str = [[e charactersIgnoringModifiers] lowercaseString];
		
		if (NSObjectIsNotEmpty(str)) {
			NSString *selectorName = [characterMap objectForKey:[NSNumber numberWithInteger:[str characterAtIndex:0]]];
			
			if (selectorName) {
				[target performSelector:NSSelectorFromString(selectorName) withObject:e];
				
				return YES;
			}
		}
	}
	
	return NO;
}

@end