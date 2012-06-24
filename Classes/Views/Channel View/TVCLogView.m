// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 07, 2012

#import "TextualApplication.h"

@implementation TVCLogView


- (void)keyDown:(NSEvent *)e
{
	if (self.keyDelegate) {
		NSUInteger m = [e modifierFlags];
		
		BOOL ctrl = (m & NSControlKeyMask);
		BOOL cmd  = (m & NSCommandKeyMask);
		BOOL alt  = (m & NSAlternateKeyMask);
		
		if (ctrl == NO && alt == NO && cmd == NO) {
			if ([self.keyDelegate respondsToSelector:@selector(logViewKeyDown:)]) {
				[self.keyDelegate logViewKeyDown:e];
			}
			
			return;
		}
	}
	
	[super keyDown:e];
}

- (void)setFrame:(NSRect)rect
{
	if (self.resizeDelegate && [self.resizeDelegate respondsToSelector:@selector(logViewWillResize)]) {
		[self.resizeDelegate logViewWillResize];
	}
	
	[super setFrame:rect];
	
	if (self.resizeDelegate && [self.resizeDelegate respondsToSelector:@selector(logViewDidResize)]) {
		[self.resizeDelegate logViewDidResize];
	}
}

- (BOOL)maintainsInactiveSelection
{
	return YES;
}

- (NSString *)contentString
{
	DOMHTMLDocument *doc = (DOMHTMLDocument *)[self mainFrameDocument];
	if (PointerIsEmpty(doc)) return NSStringEmptyPlaceholder;
	
	DOMElement *body = [doc body];
	if (PointerIsEmpty(body)) return NSStringEmptyPlaceholder;
	
	DOMHTMLElement *root = (DOMHTMLElement *)[body parentNode];
	if (PointerIsEmpty(root)) return NSStringEmptyPlaceholder;
	
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