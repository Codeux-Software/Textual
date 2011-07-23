// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation NSWindow (NSWindowHelper)

- (void)centerOfWindow:(NSWindow *)window
{
	NSPoint p = NSRectCenter(window.frame);
	
	NSRect frame = self.frame;
	NSSize size = frame.size;
	
	p.x -= (size.width / 2);
	p.y -= (size.height / 2);
	
	NSScreen *screen = window.screen;
	
	if (screen) {
		NSRect screenFrame = [screen visibleFrame];
		NSRect r = frame;
		
		r.origin = p;
		
		if (NSContainsRect(screenFrame, r) == NO) {
			r = NSRectAdjustInRect(r, screenFrame);
			p = r.origin;
		}
	}
	
	[self setFrameOrigin:p];
}

- (void)exactlyCenterWindow
{
	NSScreen *screen = [NSScreen mainScreen];
	
	if (screen) {
		NSRect rect = [screen visibleFrame];
		
		NSPoint p = NSMakePoint((rect.origin.x + (rect.size.width / 2)), 
								(rect.origin.y + (rect.size.height / 2)));
		
		NSInteger w = self.frame.size.width;
		NSInteger h = self.frame.size.height;
		
		rect = NSMakeRect((p.x - (w / 2)), (p.y - (h / 2)), w, h);
		
		[self setFrame:rect display:YES];
	}	
}

- (BOOL)isOnCurrentWorkspace
{
	return ([self isOnActiveSpace] && [self isVisible] && [NSApp keyWindow] == self);
}

@end