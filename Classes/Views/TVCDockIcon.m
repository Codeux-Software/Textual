// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on Thursday, June 07, 2012

#define _NSMainScreen()		[NSScreen mainScreen]

@interface TVCDockIcon (Private)
+ (NSString *)badgeFilename:(NSInteger)count;
@end

@implementation TVCDockIcon

/* The math is messy but it gets the job done. =) */
+ (void)drawWithoutCounts
{
	[NSApp setApplicationIconImage:[NSImage imageNamed:@"NSApplicationIcon"]];
}

+ (void)drawWithHilightCount:(NSInteger)highlightCount messageCount:(NSInteger)messageCount 
{
	if ([_NSMainScreen() userSpaceScaleFactor] == 1.0) {
		NSSize					   textSize;
		NSMutableAttributedString *textString;
		
		NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
		
		[attrs setObject:[NSColor whiteColor]						  forKey:NSForegroundColorAttributeName];
		[attrs setObject:[NSFont fontWithName:@"Helvetica" size:22.0] forKey:NSFontAttributeName];
		
		messageCount   = ((messageCount > 9999) ? 9999 : messageCount);
		highlightCount = ((highlightCount > 9999) ? 9999 : highlightCount);
		
		NSImage *appIcon	= [[NSImage imageNamed:@"NSApplicationIcon"] copy];
		NSImage *redBadge	= [NSImage imageNamed:[NSString stringWithFormat:@"DIbadge_Red_%@", [self badgeFilename:messageCount]]];
		NSImage *greenBadge = [NSImage imageNamed:[NSString stringWithFormat:@"DIbadge_Green_%@", [self badgeFilename:highlightCount]]];
		
		[appIcon lockFocus];
		
		if (messageCount >= 1) {
			textString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithInteger:messageCount] attributes:attrs];
			textSize   = [textString size];
			
			[redBadge compositeToPoint:NSMakePoint((appIcon.size.width - redBadge.size.width), 
												   (appIcon.size.height - redBadge.size.height)) operation:NSCompositeSourceOver];
			
			[textString drawAtPoint:NSMakePoint((appIcon.size.width - redBadge.size.width + ((redBadge.size.width - textSize.width) / 2)), 
												(appIcon.size.height - redBadge.size.height + ((redBadge.size.height - textSize.height) / 2) + 1))];
			
			
			if (highlightCount >= 1) {
				textString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithInteger:highlightCount] attributes:attrs];
				textSize   = [textString size];
			
				[greenBadge compositeToPoint:NSMakePoint((appIcon.size.width - greenBadge.size.width), 
														 (appIcon.size.height - greenBadge.size.height - (redBadge.size.height - 5))) 
								   operation:NSCompositeSourceOver];
				
				[textString drawAtPoint:NSMakePoint((appIcon.size.width - greenBadge.size.width + ((greenBadge.size.width - textSize.width) / 2)), 
													(appIcon.size.height - greenBadge.size.height + ((greenBadge.size.height - textSize.height) / 2) - (redBadge.size.height - 6)))];
			
			}
		} else {
			if (highlightCount >= 1) {
				textString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithInteger:highlightCount] attributes:attrs];
				textSize   = [textString size];
				
				[greenBadge compositeToPoint:NSMakePoint((appIcon.size.width - greenBadge.size.width), 
														 (appIcon.size.height - greenBadge.size.height)) operation:NSCompositeSourceOver];
				
				[textString drawAtPoint:NSMakePoint((appIcon.size.width - greenBadge.size.width + ((greenBadge.size.width - textSize.width) / 2)), 
													(appIcon.size.height - greenBadge.size.height + ((greenBadge.size.height - textSize.height) / 2) + 1))];
				
			}
		}
		
		[appIcon unlockFocus];
		
		[NSApp setApplicationIconImage:appIcon];
		
	}
}

+ (NSString *)badgeFilename:(NSInteger)count
{
	switch (count) {
		case 1 ... 99: return @"1&2.tiff"; break;
		case 100 ... 999: return @"3.tiff"; break;
		case 1000 ... 9999: return @"4.tiff"; break;
		default: break;
	}
	
	return nil;
}

@end