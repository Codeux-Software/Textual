// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#define ICON_SPACING							2.0
#define MIN_BADGE_WIDTH							22.0
#define ROW_RIGHT_MARGIN						5.0		
#define BADGE_HEIGHT							12.0		
#define BADGE_MARGIN							5.0
#define BADGE_RED_BADGE_SUBTRACTION				4.0

#define BADGE_FONT								[NSFont boldSystemFontOfSize:9]	
#define BADGE_HIGHLIGHT_BACKGROUND_COLOR		[NSColor colorWithCalibratedRed:(210/255.0) green:(15/255.0) blue:(15/255.0) alpha:1]
#define BADGE_MESSAGE_BACKGROUND_COLOR			[NSColor colorWithCalibratedRed:(152/255.0) green:(168/255.0) blue:(202/255.0) alpha:1]

/* The following class is a very hackish way to use icons and badges in an outline view.
 It is based off the PXSourceList project by Alex Rozanski */

@interface ServerList (Private)
- (NSSize)sizeOfBadgeWithMessageCount:(NSInteger)messageCount andHighlightCount:(NSInteger)highlightCount;

- (void)drawStatusBadge:(NSString *)iconName onRow:(NSInteger)rowIndex;
- (void)drawMessageCountBadge:(NSInteger)messageCount withHighlightCount:(NSInteger)highlightCount onRow:(NSInteger)rowIndex;
@end

@implementation ServerList

- (void)drawRow:(NSInteger)rowIndex clipRect:(NSRect)clipRect
{
	[super drawRow:rowIndex clipRect:clipRect];
	
	id item = [self itemAtRow:rowIndex];
	
	if ([self isGroupItem:item] == NO) {
		[self drawStatusBadge:@"status-channel-active.tif" onRow:rowIndex];
		
		NSInteger randn = TXRandomThousandNumber();
		NSInteger highlights = 0;
		NSInteger messages = 0;
		
		if (randn >= 5000) {
			highlights = TXRandomThousandNumber();
		} else {
			messages = TXRandomThousandNumber();
		}
		
		[self drawMessageCountBadge:highlights withHighlightCount:messages onRow:rowIndex];
	}
	

}

- (void)drawStatusBadge:(NSString *)iconName onRow:(NSInteger)rowIndex 
{
	NSRect cellFrame = [self frameOfCellAtColumn:0 row:rowIndex];
	
	NSSize iconSize = NSMakeSize(16, 16);
	NSRect iconRect = NSMakeRect((NSMinX(cellFrame) - iconSize.width - ICON_SPACING),
								 (NSMidY(cellFrame) - (iconSize.width / 2.0f)),
								 iconSize.width, iconSize.height);
	
	NSImage *icon = [NSImage imageNamed:iconName];
	
	if (icon) {
		NSSize actualIconSize = [icon size];
		
		if ((actualIconSize.width < iconSize.width) || 
			(actualIconSize.height<iconSize.height)) {
			
			iconRect = NSMakeRect((NSMidX(iconRect) - (actualIconSize.width / 2.0f)),
								  (NSMidY(iconRect) - (actualIconSize.height / 2.0f)),
								  actualIconSize.width, actualIconSize.height);
		}
		
		[icon drawInRect:iconRect
				fromRect:NSZeroRect
			   operation:NSCompositeSourceOver
				fraction:1
		  respectFlipped:YES hints:nil];
	}
}

- (void)drawMessageCountBadge:(NSInteger)messageCount 
		   withHighlightCount:(NSInteger)highlightCount 
						onRow:(NSInteger)rowIndex
{
	/* Establish Common Data */
	
	NSRect rowRect = [self rectOfRow:rowIndex];
	
	BOOL haveMessage	= (messageCount >= 1);
	BOOL haveHighlight	= (highlightCount >= 1);
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	NSColor *backgroundColor = [NSColor whiteColor];
	NSColor *textColor		 = [NSColor whiteColor];
	
	[attributes setObject:BADGE_FONT forKey:NSFontAttributeName];
	[attributes setObject:textColor  forKey:NSForegroundColorAttributeName];
	
	NSRect badgeFrame;
	
	NSInteger maxWidth				= 0;
	NSInteger messageCountWidth		= 0;
	NSInteger highlightCountWidth	= 0;
	
	NSSize messageCountSize;
	NSSize highlightCountSize;
	
	NSAttributedString *mcstring;
	NSAttributedString *hlcstring;
	
	if (haveMessage) {
		mcstring = [[NSAttributedString alloc] initWithString:[NSString stringWithInteger:messageCount]
												   attributes:attributes];
		
		messageCountSize    = [mcstring size];
		messageCountWidth	= messageCountSize.width;
		maxWidth			= ((BADGE_MARGIN * 2) + messageCountWidth);
	}
	
	if (haveHighlight) {
		hlcstring = [[NSAttributedString alloc] initWithString:[NSString stringWithInteger:highlightCount]
													attributes:attributes];
		
		highlightCountSize  = [hlcstring size];
		highlightCountWidth = highlightCountSize.width;
		
		if (haveMessage) {
			maxWidth += (BADGE_MARGIN + highlightCountWidth);
		} else {
			maxWidth = ((BADGE_MARGIN * 2) + highlightCountWidth);
		}
	}
	
	/* Render Actual Badges */
	
	if (haveMessage) {
		backgroundColor = BADGE_MESSAGE_BACKGROUND_COLOR;
		
		if (haveHighlight) {
			badgeFrame = NSMakeRect((NSMaxX(rowRect) - (maxWidth + (BADGE_MARGIN * 2))),
									(NSMidY(rowRect) - (BADGE_HEIGHT / 2.0)),
									((maxWidth - highlightCountWidth) + BADGE_MARGIN), BADGE_HEIGHT);
		} else {
			badgeFrame = NSMakeRect((NSMaxX(rowRect) - (maxWidth + ROW_RIGHT_MARGIN)),
									(NSMidY(rowRect) - (BADGE_HEIGHT / 2.0)),
									(maxWidth - highlightCountWidth), BADGE_HEIGHT);
		}
		
		NSBezierPath *badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeFrame
																  xRadius:(BADGE_HEIGHT / 2.0)
																  yRadius:(BADGE_HEIGHT / 2.0)];
		
		[backgroundColor set];
		[badgePath fill];
		
		NSPoint badgeTextPoint;
		
		if (haveHighlight) {
			badgeTextPoint = NSMakePoint((badgeFrame.origin.x + BADGE_MARGIN),
										 (NSMidY(badgeFrame) - (messageCountSize.height / 2.0)));
		} else {
			badgeTextPoint = NSMakePoint((NSMidX(badgeFrame) - (messageCountSize.width / 2.0)),
										 (NSMidY(badgeFrame) - (messageCountSize.height / 2.0)));
		}
		
		[mcstring drawAtPoint:badgeTextPoint];
		[mcstring drain];
	}
	
	if (haveHighlight) {
		backgroundColor = BADGE_HIGHLIGHT_BACKGROUND_COLOR;
		
		NSRect newRect, newRect2;
		NSBezierPath *badgePath;
		NSPoint badgeTextPoint;
		
		if (haveMessage) {
			badgeFrame = NSMakeRect((NSMaxX(rowRect) - ((maxWidth - (messageCountWidth + BADGE_MARGIN)) + ROW_RIGHT_MARGIN)),
									(NSMidY(rowRect) - (BADGE_HEIGHT / 2.0)),
									(maxWidth - messageCountWidth), BADGE_HEIGHT);
		} else {
			badgeFrame = NSMakeRect((NSMaxX(rowRect) - (maxWidth + ROW_RIGHT_MARGIN)),
									(NSMidY(rowRect) - (BADGE_HEIGHT / 2.0)),
									(maxWidth - messageCountWidth), BADGE_HEIGHT);
		}
		
		if (haveMessage) {
			newRect  = badgeFrame;
			newRect2 = badgeFrame;
			
			newRect.size.width = highlightCountSize.width;
			newRect2.size.width -= BADGE_RED_BADGE_SUBTRACTION;
			
			badgePath = [NSBezierPath bezierPathWithRoundedRect:newRect2
														xRadius:(BADGE_HEIGHT / 2.0)
														yRadius:(BADGE_HEIGHT / 2.0)];
			
			[badgePath appendBezierPathWithRect:newRect];
		} else {
			badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeFrame
														xRadius:(BADGE_HEIGHT / 2.0)
														yRadius:(BADGE_HEIGHT / 2.0)];
		}
		
		[backgroundColor set];
		[badgePath fill];
		
		if (haveMessage) {
			badgeTextPoint = NSMakePoint((newRect.origin.x + BADGE_MARGIN),
										 (NSMidY(badgeFrame) - (highlightCountSize.height / 2.0)));
		} else {
			badgeTextPoint = NSMakePoint((NSMidX(badgeFrame) - (highlightCountSize.width / 2.0)),
										 (NSMidY(badgeFrame) - (highlightCountSize.height / 2.0)));
		}
		
		[hlcstring drawAtPoint:badgeTextPoint];
		[hlcstring drain];
	}
}

- (NSRect)rectOfRow:(NSInteger)row
{
	NSRect rect = [super rectOfRow:row];
	
	id childItem  = [self itemAtRow:row];
	id parentItem = [self parentForItem:childItem];
	
	if (parentItem) {
		row = [self rowForItem:parentItem];
	}
	
	if ([self isGroupItem:childItem]) {
		rect.origin.y -= 3.0;
		rect.size.height += 2;
	} else {
		rect.origin.y += 2.0;
	}
	
	return rect;
}

- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row 
{
	NSRect superFrame = [super frameOfCellAtColumn:column row:row];
	
	id childItem  = [self itemAtRow:row];
	
	if ([self isGroupItem:childItem]) {
		superFrame.origin.y -= 1;
	} else {
		superFrame.origin.y -= 0;
	}
	
	return superFrame;
}

@end