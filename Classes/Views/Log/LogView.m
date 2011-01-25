// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation LogView

@synthesize keyDelegate;
@synthesize resizeDelegate;

- (void)keyDown:(NSEvent *)e
{
	if (keyDelegate) {
		NSUInteger m = [e modifierFlags];
		
		BOOL cmd = ((m & NSCommandKeyMask) != 0);
		BOOL ctrl = ((m & NSControlKeyMask) != 0);
		BOOL alt = ((m & NSAlternateKeyMask) != 0);
		
		if (ctrl == NO && alt == NO && cmd == NO) {
			if ([keyDelegate respondsToSelector:@selector(logViewKeyDown:)]) {
				[keyDelegate logViewKeyDown:e];
			}
			
			return;
		}
	}
	
	[super keyDown:e];
}

- (void)setFrame:(NSRect)rect
{
	if (resizeDelegate && [resizeDelegate respondsToSelector:@selector(logViewWillResize)]) {
		[resizeDelegate logViewWillResize];
	}
	
	[super setFrame:rect];
	
	if (resizeDelegate && [resizeDelegate respondsToSelector:@selector(logViewDidResize)]) {
		[resizeDelegate logViewDidResize];
	}
}

- (BOOL)maintainsInactiveSelection
{
	return YES;
}

- (NSString *)contentString
{
	DOMHTMLDocument *doc = (DOMHTMLDocument *)[self mainFrameDocument];
	if (doc == nil) return @"";
	
	DOMElement *body = [doc body];
	if (body == nil) return @"";
	
	DOMHTMLElement *root = (DOMHTMLElement *)[body parentNode];
	if (root == nil) return @"";
	
	return [root outerHTML];
}

- (WebScriptObject *)js_api
{
	return [[self windowScriptObject] evaluateWebScript:@"Textual"];
}

- (void)clearSelection
{
	[self setSelectedDOMRange:nil affinity:NSSelectionAffinityDownstream];
}

- (BOOL)hasSelection
{
	return BOOLReverseValue(NSStringIsEmpty([self selection]));
}

- (NSString *)selection
{
	DOMRange *range = [self selectedDOMRange];
	if (range == nil) return nil;
	
	return [range toString];
}

@end