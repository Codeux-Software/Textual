// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 08, 2012

@implementation KeyEventHandler

@synthesize target;
@synthesize codeHandlerMap;
@synthesize characterHandlerMap;

- (id)init
{
	if ((self = [super init])) {
		self.codeHandlerMap = [NSMutableDictionary new];
		self.characterHandlerMap = [NSMutableDictionary new];
	}
	
	return self;
}

- (void)registerSelector:(SEL)selector key:(NSInteger)code modifiers:(NSUInteger)mods
{
	NSNumber *modsKey = [NSNumber numberWithUnsignedInteger:mods];
	NSMutableDictionary *map = [self.codeHandlerMap objectForKey:modsKey];
	
	if (NSObjectIsEmpty(map)) {
		map = [NSMutableDictionary dictionary];
		
		[self.codeHandlerMap setObject:map forKey:modsKey];
	}
	
	[map setObject:NSStringFromSelector(selector) forKey:NSNumberWithInteger(code)];
}

- (void)registerSelector:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods
{
	NSNumber *modsKey = [NSNumber numberWithUnsignedInteger:mods];
	NSMutableDictionary *map = [self.characterHandlerMap objectForKey:modsKey];
	
	if (NSObjectIsEmpty(map)) {
		map = [NSMutableDictionary dictionary];
		
		[self.characterHandlerMap setObject:map forKey:modsKey];
	}
	
	[map setObject:NSStringFromSelector(selector) forKey:NSNumberWithInteger(c)];
}

- (void)registerSelector:(SEL)selector characters:(NSRange)characterRange modifiers:(NSUInteger)mods
{
	NSNumber *modsKey = [NSNumber numberWithUnsignedInteger:mods];
	NSMutableDictionary *map = [self.characterHandlerMap objectForKey:modsKey];
	
	if (NSObjectIsEmpty(map)) {
		map = [NSMutableDictionary dictionary];
		
		[self.characterHandlerMap setObject:map forKey:modsKey];
	}
	
	NSInteger from = characterRange.location;
	NSInteger to = NSMaxRange(characterRange);
	
	for (NSInteger i = from; i < to; ++i) {
		NSNumber *charKey = NSNumberWithInteger(i);
		
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
	
	NSMutableDictionary *codeMap = [self.codeHandlerMap objectForKey:modsKey];
	
	if (codeMap) {
		NSString *selectorName = [codeMap objectForKey:NSNumberWithInteger([e keyCode])];

		if (selectorName) {
			
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
			[self.target performSelector:NSSelectorFromString(selectorName) withObject:e];
#pragma clang diagnostic pop
			
			return YES;
		}
	}
	
	NSMutableDictionary *characterMap = [self.characterHandlerMap objectForKey:modsKey];
	
	if (characterMap) {
		NSString *str = [[e charactersIgnoringModifiers] lowercaseString];
		
		if (NSObjectIsNotEmpty(str)) {
			NSString *selectorName = [characterMap objectForKey:NSNumberWithInteger([str characterAtIndex:0])];
			
			if (selectorName) {
				
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
				[self.target performSelector:NSSelectorFromString(selectorName) withObject:e];
#pragma clang diagnostic pop
				
				return YES;
			}
		}
	}
	
	return NO;
}

@end