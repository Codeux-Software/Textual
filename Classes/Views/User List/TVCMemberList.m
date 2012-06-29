// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 07, 2012

#import "TextualApplication.h"

@implementation TVCMemberList

static NSColor *_invertedBackgroundColor;

- (void)updateBackgroundColor
{
	BOOL invertedColors = [TPCPreferences invertSidebarColors];
	
	if (invertedColors) {
		if (PointerIsEmpty(_invertedBackgroundColor)) {
			_invertedBackgroundColor = [NSColor internalCalibratedRed:38.0 green:38.0 blue:38.0 alpha:1];
		}
		
		[self setBackgroundColor:_invertedBackgroundColor];
	} else {
		[self setBackgroundColor:[NSColor sourceListBackgroundColor]];
	}
}

- (void)keyDown:(NSEvent *)e
{
	if (self.keyDelegate) {
		switch ([e keyCode]) {
			case 123 ... 126:
			case 116:
			case 121:
				break;
			default:
				if ([self.keyDelegate respondsToSelector:@selector(memberListViewKeyDown:)]) {
					[self.keyDelegate memberListViewKeyDown:e];
				}
				
				break;
		}
	}
}

- (void)drawContextMenuHighlightForRow:(int)row
{
    // Do not draw focus ring …
}

@end