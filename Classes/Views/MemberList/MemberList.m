// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation MemberList

- (void)keyDown:(NSEvent *)e
{
	if (keyDelegate) {
		switch ([e keyCode]) {
			case 123 ... 126:
			case 116:
			case 121:
				break;
			default:
				if ([keyDelegate respondsToSelector:@selector(memberListViewKeyDown:)]) {
					[keyDelegate memberListViewKeyDown:e];
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