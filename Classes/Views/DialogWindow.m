// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// You can redistribute it and/or modify it under the new BSD license.

#import "DialogWindow.h"

@implementation DialogWindow

- (void)sendEvent:(NSEvent *)e
{
	/*if ([e type] == NSKeyDown) {
		NSInputManager *im = [NSInputManager currentInputManager];
		if (!im || !im.markedRange.length) {
			NSInteger k = [e keyCode];
			NSUInteger m = [e modifierFlags];
			BOOL cmd = ((m & NSCommandKeyMask) != 0);
			BOOL ctrl = ((m & NSControlKeyMask) != 0);
			BOOL shift = ((m & NSShiftKeyMask) != 0);
			BOOL alt = ((m & NSAlternateKeyMask) != 0);
			
			if (!shift && !ctrl && !alt && !cmd) {
				// no mods
				switch (k) {
					case 0x35:	// esc
						[self close];
						return;
				}
			}
		}
	}*/
	
	[super sendEvent:e];
}

@end