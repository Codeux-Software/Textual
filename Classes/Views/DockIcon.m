// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define _NSMainScreen()		[NSScreen mainScreen]

@interface DockIcon (Private)
+ (NSString *)badgeFilename:(NSInteger)count;
@end

@implementation DockIcon

/* The math is messy but it gets the job done. =) */

+ (void)drawWithoutCounts
{
	[NSApp setApplicationIconImage:[NSImage imageNamed:@"NSApplicationIcon"]];
}

+ (void)drawWithHilightCount:(NSInteger)highlight_count messageCount:(NSInteger)message_count 
{
	if ([_NSMainScreen() userSpaceScaleFactor] == 1.0) {
		NSSize					   textSize;
		NSMutableAttributedString *textString;
		
		NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
		
		[attrs setObject:[NSColor whiteColor]						  forKey:NSForegroundColorAttributeName];
		[attrs setObject:[NSFont fontWithName:@"Helvetica" size:22.0] forKey:NSFontAttributeName];
		
		message_count   = ((message_count > 9999) ? 9999 : message_count);
		highlight_count = ((highlight_count > 9999) ? 9999 : highlight_count);
		
		NSImage *appIcon	= [[NSImage imageNamed:@"NSApplicationIcon"] copy];
		NSImage *redBadge	= [NSImage imageNamed:[NSString stringWithFormat:@"DIbadge_Red_%@", [self badgeFilename:message_count]]];
		NSImage *greenBadge = [NSImage imageNamed:[NSString stringWithFormat:@"DIbadge_Green_%@", [self badgeFilename:highlight_count]]];
		
		[appIcon lockFocus];
		
		if (message_count >= 1) {
			textString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithInteger:message_count] attributes:attrs];
			textSize   = [textString size];
			
			[redBadge compositeToPoint:NSMakePoint((appIcon.size.width - redBadge.size.width), 
												   (appIcon.size.height - redBadge.size.height)) operation:NSCompositeSourceOver];
			
			[textString drawAtPoint:NSMakePoint((appIcon.size.width - redBadge.size.width + ((redBadge.size.width - textSize.width) / 2)), 
												(appIcon.size.height - redBadge.size.height + ((redBadge.size.height - textSize.height) / 2) + 1))];
			
			[textString drain];
			
			if (highlight_count >= 1) {
				textString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithInteger:highlight_count] attributes:attrs];
				textSize   = [textString size];
			
				[greenBadge compositeToPoint:NSMakePoint((appIcon.size.width - greenBadge.size.width), 
														 (appIcon.size.height - greenBadge.size.height - (redBadge.size.height - 5))) 
								   operation:NSCompositeSourceOver];
				
				[textString drawAtPoint:NSMakePoint((appIcon.size.width - greenBadge.size.width + ((greenBadge.size.width - textSize.width) / 2)), 
													(appIcon.size.height - greenBadge.size.height + ((greenBadge.size.height - textSize.height) / 2) - (redBadge.size.height - 6)))];
			
				[textString drain];
			}
		} else {
			if (highlight_count >= 1) {
				textString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithInteger:highlight_count] attributes:attrs];
				textSize   = [textString size];
				
				[greenBadge compositeToPoint:NSMakePoint((appIcon.size.width - greenBadge.size.width), 
														 (appIcon.size.height - greenBadge.size.height)) operation:NSCompositeSourceOver];
				
				[textString drawAtPoint:NSMakePoint((appIcon.size.width - greenBadge.size.width + ((greenBadge.size.width - textSize.width) / 2)), 
													(appIcon.size.height - greenBadge.size.height + ((greenBadge.size.height - textSize.height) / 2) + 1))];
				
				[textString drain];
			}
		}
		
		[appIcon unlockFocus];
		
		[NSApp setApplicationIconImage:appIcon];
		
		[appIcon drain];
	}
}

+ (NSString *)badgeFilename:(NSInteger)count
{
	switch (count) {
		case 1 ... 99:
			return @"1&2.tiff";
			break;
		case 100 ... 999:
			return @"3.tiff";
			break;
		case 1000 ... 9999:
			return @"4.tiff";
			break;
	}
	
	return nil;
}

@end