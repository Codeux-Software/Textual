// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#define DOUBLE_CLICK_RADIUS	3

@implementation LogScriptEventSink

@synthesize owner;
@synthesize policy;
@synthesize x;
@synthesize y;
@synthesize lastClickTime;

- (id)init
{
	if ((self = [super init])) {
		x = -10000;
		y = -10000;
	}
	
	return self;
}

- (void)dealloc
{
	[policy drain];
	
	[super dealloc];
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
	[owner logViewOnDoubleClick:e];
}

- (BOOL)shouldStopDoubleClick:(id)e
{
	NSInteger d  = DOUBLE_CLICK_RADIUS;
	NSInteger cx = [[e valueForKey:@"clientX"] integerValue];
	NSInteger cy = [[e valueForKey:@"clientY"] integerValue];
	
	BOOL res = NO;
	
	CFAbsoluteTime now = CFAbsoluteTimeGetCurrent();
	
	if ((x - d) <= cx && cx <= (x + d) && 
		(y - d) <= cy && cy <= (y + d)) {
		
		if (now < (lastClickTime + [NSEvent doubleClickInterval])) {
			res = YES;
		}
	}
	
	lastClickTime = now;
	
	x = cx;
	y = cy;
	
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
        [URLOpener open:[NSURL URLWithString:object.href]];
        
        return @"true";
    }
}

- (void)setUrl:(NSString *)s
{
	[policy setUrl:[s gtm_stringByUnescapingFromHTML]];
}

- (void)setAddr:(NSString *)s
{
	[policy setAddr:[s gtm_stringByUnescapingFromHTML]];
}

- (void)setNick:(NSString *)s
{
	[policy setNick:[s gtm_stringByUnescapingFromHTML]];
}

- (void)setChan:(NSString *)s
{
	[policy setChan:[s gtm_stringByUnescapingFromHTML]];
}

- (void)channelDoubleClicked
{
	[policy channelDoubleClicked];
}

- (void)nicknameDoubleClicked
{
	[policy nicknameDoubleClicked];
}

- (void)print:(NSString *)s
{
}

@end