// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "DockIcon.h"

@implementation DockIcon

/* The math is messy but it gets the job done. =) */

+ (void)drawWithoutCounts
{
	[NSApp setApplicationIconImage:[NSImage imageNamed:@"NSApplicationIcon"]];
}

+ (void)drawWithHilightCount:(NSInteger)highlight_count 
				   messageCount:(NSInteger)message_count 
{
	NSScreen *scaleCheck = [NSScreen alloc];
	
	if ([[NSString stringWithFormat:@"%f", [scaleCheck userSpaceScaleFactor]] hasPrefix:@"1.0"]) {
		NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
	
		NSSize textSize;
		NSString *iconRep;
		NSMutableAttributedString* textString;
		NSFont *font = [NSFont fontWithName:@"Helvetica" size:22.0];
		NSMutableDictionary *attrs = [NSMutableDictionary dictionary];
		
		[attrs setObject:font forKey:NSFontAttributeName];
		[attrs setObject:[NSColor whiteColor] forKey:NSForegroundColorAttributeName];
		
		highlight_count = ((highlight_count > 9999) ? 9999 : highlight_count);
		message_count = ((message_count > 9999) ? 9999 : message_count);
		
		NSImage *appIcon = [[NSImage imageNamed:@"NSApplicationIcon"] copy];
		NSImage *redBadge = [[NSImage alloc] initWithContentsOfFile:[[Preferences whereResourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"Images/Badges/Red/%@", [self badgeFilename:message_count]]]];
		NSImage *greenBadge = [[NSImage alloc] initWithContentsOfFile:[[Preferences whereResourcePath] stringByAppendingPathComponent:[NSString stringWithFormat:@"Images/Badges/Green/%@", [self badgeFilename:highlight_count]]]];
		
		[appIcon lockFocus];
		
		if (message_count >= 1) {
			[redBadge compositeToPoint:NSMakePoint((appIcon.size.width - redBadge.size.width), (appIcon.size.height - redBadge.size.height)) operation:NSCompositeSourceOver];
			
			iconRep = [NSString stringWithFormat:@"%i", message_count];
			
			textSize = [iconRep sizeWithAttributes:attrs];
			textString = [[[NSMutableAttributedString alloc] initWithString:iconRep attributes:attrs] autorelease];
			[textString drawAtPoint:NSMakePoint((appIcon.size.width - redBadge.size.width + ((redBadge.size.width - textSize.width) / 2)), (appIcon.size.height - redBadge.size.height + ((redBadge.size.height - textSize.height) / 2) + 1))];
			
			if (highlight_count >= 1) {
				[greenBadge compositeToPoint:NSMakePoint((appIcon.size.width - greenBadge.size.width), (appIcon.size.height - greenBadge.size.height - (redBadge.size.height - 5))) operation:NSCompositeSourceOver];
				
				iconRep = [NSString stringWithFormat:@"%i", highlight_count];
				
				textSize = [iconRep sizeWithAttributes:attrs];
				textString = [[[NSMutableAttributedString alloc] initWithString:iconRep attributes:attrs] autorelease];
				[textString drawAtPoint:NSMakePoint((appIcon.size.width - greenBadge.size.width + ((greenBadge.size.width - textSize.width) / 2)), (appIcon.size.height - greenBadge.size.height + ((greenBadge.size.height - textSize.height) / 2) - (redBadge.size.height - 6)))];
			}
		} else {
			if (highlight_count >= 1) {
				[greenBadge compositeToPoint:NSMakePoint((appIcon.size.width - greenBadge.size.width), (appIcon.size.height - greenBadge.size.height)) operation:NSCompositeSourceOver];
				
				iconRep = [NSString stringWithFormat:@"%i", highlight_count];
				
				textSize = [iconRep sizeWithAttributes:attrs];
				textString = [[[NSMutableAttributedString alloc] initWithString:iconRep attributes:attrs] autorelease];
				[textString drawAtPoint:NSMakePoint((appIcon.size.width - greenBadge.size.width + ((greenBadge.size.width - textSize.width) / 2)), (appIcon.size.height - greenBadge.size.height + ((greenBadge.size.height - textSize.height) / 2) + 1))];
			}
		}
		
		[appIcon unlockFocus];
		
		[NSApp setApplicationIconImage:appIcon];
		
		[appIcon release];
		[redBadge release];
		[greenBadge release];
		
		[pool drain];
	}
	
	[scaleCheck release];
}

+ (NSString*)badgeFilename:(NSInteger)count
{
	switch (count) {
		case 1 ... 99:
			return @"badge1&2.tiff";
			break;
		case 100 ... 999:
			return @"badge3.tiff";
			break;
		case 1000 ... 9999:
			return @"badge4.tiff";
			break;
		default:
			return @"badge4.tiff";
			break;
	}
}

@end