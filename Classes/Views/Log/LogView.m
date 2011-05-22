// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

@implementation LogView

@synthesize keyDelegate;
@synthesize resizeDelegate;

- (void)keyDown:(NSEvent *)e
{
	if (keyDelegate) {
		NSUInteger m = [e modifierFlags];
		
		BOOL ctrl = (m & NSControlKeyMask);
		BOOL cmd  = (m & NSCommandKeyMask);
		BOOL alt  = (m & NSAlternateKeyMask);
		
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
	if (PointerIsEmpty(doc)) return NSNullObject;
	
	DOMElement *body = [doc body];
	if (PointerIsEmpty(body)) return NSNullObject;
	
	DOMHTMLElement *root = (DOMHTMLElement *)[body parentNode];
	if (PointerIsEmpty(root)) return NSNullObject;
	
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
	return BOOLReverseValue(NSObjectIsEmpty([self selection]));
}

- (NSString *)selection
{
	DOMRange *range = [self selectedDOMRange];
	if (PointerIsEmpty(range)) return nil;
	
	return [range toString];
}

@end