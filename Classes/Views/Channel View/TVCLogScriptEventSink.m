// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 07, 2012

#import "TextualApplication.h"

#define _doubleClickRadius		3

@implementation TVCLogScriptEventSink


- (id)init
{
	if ((self = [super init])) {
		self.x = -10000;
		self.y = -10000;
	}
	
	return self;
}


+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel
{
	return NO;
}

+ (NSString *)webScriptNameForSelector:(SEL)sel
{
	NSString *s = NSStringFromSelector(sel);
	
	if ([s hasSuffix:@":"]) {
		return [s safeSubstringToIndex:(s.length - 1)];
	}
	
	return nil;
}

+ (BOOL)isKeyExcludedFromWebScript:(const char *)name
{
	return YES;
}

+ (NSString *)webScriptNameForKey:(const char *)name
{
	return nil;
}

- (void)onDblClick:(id)e
{
	[self.owner logViewOnDoubleClick:e];
}

- (BOOL)shouldStopDoubleClick:(id)e
{
	NSInteger d  = _doubleClickRadius;
	NSInteger cx = [[e valueForKey:@"clientX"] integerValue];
	NSInteger cy = [[e valueForKey:@"clientY"] integerValue];
	
	BOOL res = NO;
	
	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
	
	if ((self.x - d) <= cx && cx <= (self.x + d) && 
		(self.y - d) <= cy && cy <= (self.y + d)) {
		
		if (now < (self.lastClickTime + [NSEvent doubleClickInterval])) {
			res = YES;
		}
	}
	
	self.lastClickTime = now;
	
	self.x = cx;
	self.y = cy;
	
	return res;
}

- (void)logToConsole:(NSString *)message
{
    NSLog(@"JavaScript: %@", message);
}

- (NSString *)hideInlineImage:(DOMHTMLAnchorElement *)object
{	
    if ([NSEvent modifierFlags] & NSShiftKeyMask) {
        [object.parentNode removeChild:object];
        
        return @"false";
    } else {
        return @"true";
    }
}

- (void)setUrl:(NSString *)s
{
	[self.policy setUrl:[s gtm_stringByUnescapingFromHTML]];
}

- (void)setAddr:(NSString *)s
{
	[self.policy setAddr:[s gtm_stringByUnescapingFromHTML]];
}

- (void)setNick:(NSString *)s
{
	[self.policy setNick:[s gtm_stringByUnescapingFromHTML]];
}

- (void)setChan:(NSString *)s
{
	[self.policy setChan:[s gtm_stringByUnescapingFromHTML]];
}

- (void)channelDoubleClicked
{
	[self.policy channelDoubleClicked];
}

- (void)nicknameDoubleClicked
{
	[self.policy nicknameDoubleClicked];
}

- (void)print:(NSString *)s
{
}

@end