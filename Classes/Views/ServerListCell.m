// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

/* This class is based off the open source PXSourceList toolkit developed by Alex Rozanski */

#define ICON_SPACING							5.0
#define ROW_RIGHT_MARGIN						-5.0	
#define MIN_BADGE_WIDTH							22.0
#define BADGE_HEIGHT							14.0		
#define BADGE_MARGIN							5.0

#define BADGE_FONT								[_NSFontManager() fontWithFamily:@"Helvetica" traits:0 weight:15 size:10.5]
#define BADGE_MESSAGE_BACKGROUND_COLOR			[NSColor colorWithCalibratedRed:(152/255.0) green:(168/255.0) blue:(202/255.0) alpha:1]
#define BADGE_HIGHLIGHT_BACKGROUND_COLOR		[NSColor colorWithCalibratedRed:(210/255.0) green:(15/255.0) blue:(15/255.0) alpha:1]

@implementation ServerListCell

@synthesize parent;
@synthesize cellItem;

#pragma mark -
#pragma mark Status Icon

- (void)drawStatusBadge:(NSString *)iconName inCell:(NSRect)cellFrame
{
	NSInteger extraMath = 0;
	
	if ([iconName isEqualNoCase:@"NSUserGroup"]) {
		extraMath = 1;
	} 
	
	NSSize iconSize = NSMakeSize(16, 16);
	NSRect iconRect = NSMakeRect( (NSMinX(cellFrame) - iconSize.width - ICON_SPACING),
								 ((NSMidY(cellFrame) - (iconSize.width / 2.0f) - extraMath)),
								 iconSize.width, iconSize.height);
	
	NSImage *icon = [NSImage imageNamed:iconName];
	
	if (icon) {
		NSSize actualIconSize = [icon size];
		
		if ((actualIconSize.width < iconSize.width) || 
			(actualIconSize.height < iconSize.height)) {
			
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

#pragma mark -
#pragma mark Status Badge

- (NSAttributedString *)messageCountBadgeText:(NSInteger)messageCount
{
	NSString *messageCountString;
	
	if ([_NSUserDefaults() boolForKey:@"ForceServerListBadgeLocalization"]) {
		messageCountString = TXFormattedNumber(messageCount);
	} else {
		messageCountString = [NSString stringWithInteger:messageCount];
	}
	
	NSMutableDictionary *attributes = [NSMutableDictionary dictionary];
	
	NSColor *textColor = [NSColor whiteColor];
	
	[attributes setObject:BADGE_FONT forKey:NSFontAttributeName];
	[attributes setObject:textColor  forKey:NSForegroundColorAttributeName];
	
	NSAttributedString *mcstring = [[NSAttributedString alloc] initWithString:messageCountString
																   attributes:attributes];
	
	return [mcstring autodrain];
}

- (NSRect)messageCountBadgeRect:(NSRect)cellFrame withText:(NSAttributedString *)mcstring
{
	NSRect badgeFrame;
	
	NSSize    messageCountSize  = [mcstring size];
	NSInteger messageCountWidth = (messageCountSize.width + (BADGE_MARGIN * 2));
	
	badgeFrame = NSMakeRect((NSMaxX(cellFrame) - (ROW_RIGHT_MARGIN + messageCountWidth)),
							(NSMidY(cellFrame) - (BADGE_HEIGHT / 2.0)),
							messageCountWidth, BADGE_HEIGHT);
	
	if (badgeFrame.size.width < MIN_BADGE_WIDTH) {
		NSInteger widthDiff = (MIN_BADGE_WIDTH - badgeFrame.size.width);
		
		badgeFrame.size.width += widthDiff;
		badgeFrame.origin.x   -= widthDiff;
	}
	
	return badgeFrame;
}

- (NSInteger)drawMessageCountBadge:(NSAttributedString *)mcstring inCell:(NSRect)badgeFrame withHighlighgt:(BOOL)highlight
{
	NSSize messageCountSize = [mcstring size];
	
	NSColor *backgroundColor = [NSColor whiteColor];
	
	NSRect shadowFrame;
	
	shadowFrame = badgeFrame;
	shadowFrame.origin.y += 1;
	
	NSBezierPath *badgePath = [NSBezierPath bezierPathWithRoundedRect:shadowFrame
															  xRadius:(BADGE_HEIGHT / 2.0)
															  yRadius:(BADGE_HEIGHT / 2.0)];
	
	[backgroundColor set];
	[badgePath fill];
	
	if (highlight) {
		backgroundColor = BADGE_HIGHLIGHT_BACKGROUND_COLOR;
	} else {
		backgroundColor = BADGE_MESSAGE_BACKGROUND_COLOR;
	}
	
	badgePath = [NSBezierPath bezierPathWithRoundedRect:badgeFrame
												xRadius:(BADGE_HEIGHT / 2.0)
												yRadius:(BADGE_HEIGHT / 2.0)];
	
	[backgroundColor set];
	[badgePath fill];
	
	NSPoint badgeTextPoint;
	
	badgeTextPoint = NSMakePoint( (NSMidX(badgeFrame) - (messageCountSize.width / 2.0)),
								 ((NSMidY(badgeFrame) - (messageCountSize.height / 2.0)) + 1));
	
	[mcstring drawAtPoint:badgeTextPoint];
	
	return badgeFrame.size.width;
}

#pragma mark -
#pragma mark Cell Drawing

- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView
{
	NSInteger selectedRow = [parent selectedRow];
	
	if (cellItem) {
		BOOL showDebugDataForCell = NO;
		
		/* Hidden setting used for debugging. There is no
		 problem if a normal user finds it and uses it. */
		if ([_NSUserDefaults() boolForKey:@"ForceRandomServerListBadges"]) {
			id parentObject = [parent parentForItem:cellItem];
			
			NSInteger groupIndex  = 0;
			NSInteger parentIndex = [parent rowForItem:parentObject];
			
			NSArray  *groups = [parent groupItems];
			NSNumber *groupn = [NSNumber numberWithInteger:parentIndex];
			
			groupIndex = [groups indexOfObject:groupn];
			
			if (groupIndex == 1) { // Only show debug data for second group
				showDebugDataForCell = YES;
			}
		}
		
		NSInteger rowIndex = [parent rowForItem:cellItem];
		
		IRCClient  *client  = cellItem.log.client;
		IRCChannel *channel = cellItem.log.channel;
		
		NSAttributedString			*stringValue	= [self attributedStringValue];	
		NSMutableAttributedString	*newValue		= [stringValue mutableCopy];
		
		NSShadow *itemShadow = [NSShadow new];
		
		if ([parent isGroupItem:cellItem] == NO) {
			if (client.isConnecting) {
				[self drawStatusBadge:@"status-channel-connecting.tif" inCell:cellFrame];
			} else if (channel.isChannel) {
				if (channel.isActive || showDebugDataForCell) {
					[self drawStatusBadge:@"status-channel-active.tif" inCell:cellFrame];
				} else {
					[self drawStatusBadge:@"status-channel-inactive.tif" inCell:cellFrame];
				} 
			} else {
				[self drawStatusBadge:@"NSUserGroup" inCell:cellFrame];
			}
			
			if (NSDissimilarObjects(selectedRow, rowIndex)) {
				NSInteger unreadCount  = cellItem.treeUnreadCount;
				NSInteger keywordCount = cellItem.keywordCount;
				
				if (showDebugDataForCell) {
					unreadCount = TXRandomNumber(999);
					
					if (unreadCount < 100) {
						keywordCount = 1;
					}
				}
				
				if (unreadCount >= 1) {
					NSAttributedString *mcstring = [self messageCountBadgeText:unreadCount];
					
					NSRect badgeRect = [self messageCountBadgeRect:cellFrame withText:mcstring];
					
					[self drawMessageCountBadge:mcstring inCell:badgeRect withHighlighgt:(keywordCount >= 1)];
					
					cellFrame.size.width -= badgeRect.size.width;
				}
				
				[itemShadow setShadowColor:[NSColor whiteColor]];	
			} else {
				[itemShadow setShadowColor:[NSColor darkGrayColor]];
			}
			
			cellFrame.origin.y += 3;
			
			[itemShadow setShadowOffset:NSMakeSize(0, -1)];
			
			[newValue addAttribute:NSShadowAttributeName value:itemShadow range:NSMakeRange(0, [newValue length])];
			[newValue drawInRect:cellFrame];
		} else {
			cellFrame.origin.y += 6;
			
			NSColor *controlColor	= [NSColor outlineViewHeaderTextColor];
			NSFont  *groupFont		= [NSFont fontWithName:@"LucidaGrande-Bold" size:12.0];
			
			[itemShadow setShadowOffset:NSMakeSize(1, -1)];
			
			if (NSDissimilarObjects(selectedRow, rowIndex)) {
				[itemShadow setShadowColor:[NSColor whiteColor]];	
			} else {
				controlColor = [NSColor alternateSelectedControlTextColor];
				
				[itemShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.00 alpha:0.30]];
			}
			
			NSRange textRange = NSMakeRange(0, [newValue length]);
			
			[newValue addAttribute:NSFontAttributeName				value:groupFont		range:textRange];
			[newValue addAttribute:NSShadowAttributeName			value:itemShadow	range:textRange];
			[newValue addAttribute:NSForegroundColorAttributeName	value:controlColor	range:textRange];
			
			[newValue drawInRect:cellFrame];
		}
		
		[newValue drain];
		[itemShadow drain];
	}
}

@end