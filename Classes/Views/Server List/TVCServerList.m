/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of the Textual IRC Client & Codeux Software nor the
      names of its contributors may be used to endorse or promote products
      derived from this software without specific prior written permission.

 THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 SUCH DAMAGE.

 *********************************************************************** */

#import "TextualApplication.h"

@interface TVCServerList ()
@property (nonatomic, assign) BOOL viewBeenLiveResizedBefore;
@end

@implementation TVCServerList

#pragma mark -
#pragma mark Additions/Removal

- (void)addItemToList:(NSInteger)index inParent:(id)parent
{
	NSAssertReturn(index >= 0);

	[self insertItemsAtIndexes:[NSIndexSet indexSetWithIndex:index]
					  inParent:parent
				 withAnimation:(NSTableViewAnimationEffectFade | NSTableViewAnimationSlideRight)];

	if (parent) {
		[self reloadItem:parent];
	}
}

- (void)removeItemFromList:(id)oldObject
{
	/* Get the row. */
	NSInteger rowIndex = [self rowForItem:oldObject];

	NSAssertReturn(rowIndex >= 0);

	/* Do we have a parent? */
	id parentItem = [self parentForItem:oldObject];

	if ([parentItem isKindOfClass:[IRCClient class]]) {
		/* We have a parent, get the index of the child. */
		NSArray *childrenItems = [self rowsFromParentGroup:parentItem];

		rowIndex = [childrenItems indexOfObject:oldObject];
	} else {
		/* We are the parent. Get our own index. */
		NSArray *groupItems = [self groupItems];
		
		rowIndex = [groupItems indexOfObject:oldObject];
	}

	/* Remove object. */
	NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:rowIndex];

	[self removeItemsAtIndexes:indexSet
					  inParent:parentItem
				 withAnimation:(NSTableViewAnimationEffectFade | NSTableViewAnimationSlideLeft)];

	if (parentItem) {
		[self reloadItem:parentItem];
	}
}

#pragma mark -
#pragma mark Drawing Updates

- (void)reloadAllDrawings:(BOOL)doNotLimit
{
	for (NSInteger i = 0; i < [self numberOfRows]; i++) {
		[self updateDrawingForRow:i];
	}
	
	[self setNeedsDisplay:YES];
}

- (void)reloadAllDrawings
{
	[self reloadAllDrawings:NO];
}

- (void)updateDrawingForItem:(IRCTreeItem *)cellItem
{
	PointerIsEmptyAssert(cellItem);
	
	NSInteger rowIndex = [self rowForItem:cellItem];
	
	NSAssertReturn(rowIndex >= 0);
	
	[self updateDrawingForRow:rowIndex];
}

- (void)updateDrawingForRow:(NSInteger)rowIndex
{
	NSAssertReturn(rowIndex >= 0);
	
	id rowView = [self viewAtColumn:0 row:rowIndex makeIfNecessary:NO];
	
	BOOL isGroupItem = [rowView isKindOfClass:[TVCServerListCellGroupItem class]];
	BOOL isChildItem = [rowView isKindOfClass:[TVCServerListCellChildItem class]];
	
	if (isGroupItem || isChildItem) {
		NSRect cellFrame = [self frameOfCellAtColumn:0 row:rowIndex];
		
		[rowView updateDrawing:cellFrame];
		
		if (isGroupItem) {
			[rowView updateGroupDisclosureTriangle];
		}
	}
}

- (void)updateBackgroundColor
{
}

- (BOOL)allowsVibrancy
{
	return YES;
}

- (void)viewWillStartLiveResize
{
	self.viewBeenLiveResizedBefore = YES;
}

- (NSRect)rectOfColumn:(NSInteger)column
{
	NSRect superRect = [super rectOfColumn:column];
	
	/* This is an extremely ugly hack to fix a bug with the underlying
	 drawing engine of NSOutlineView. I thought about submitting a radar
	 for this particular case, but never got around to it because I 
	 managed to fix it here. If you would like to submit one on behalf
	 of me, go ahead. */
	
	if (self.viewBeenLiveResizedBefore == NO) {
		superRect.size.width += 10;
	}
	
	return superRect;
}

- (NSScrollView *)scrollView
{
	return [self enclosingScrollView];
}

- (Class)userInterfaceObjects
{
	if ([CSFWSystemInformation featureAvailableToOSXYosemite]) {
		return [TVCServerListLightYosemiteUserInterface class];
	} else {
		return nil;
	}
}

#pragma mark -
#pragma mark Events

- (NSMenu *)menuForEvent:(NSEvent *)e
{
	NSPoint p = [self convertPoint:[e locationInWindow] fromView:nil];

	NSInteger i = [self rowAtPoint:p];

	if (i >= 0 && NSDissimilarObjects(i, [self selectedRow])) {
		[self selectItemAtIndex:i];
	} else if (i == -1) {
		return [menuController() addServerMenu];
	}

	return [self menu];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	TVCMainWindowNegateActionWithAttachedSheet();
	
	[super rightMouseDown:theEvent];
}

- (void)keyDown:(NSEvent *)e
{
	if (self.keyDelegate) {
		switch ([e keyCode]) {
			case 123 ... 126:
			case 116:
			case 121:
			{
				break;
			}
			default:
			{
				if ([self.keyDelegate respondsToSelector:@selector(serverListKeyDown:)]) {
					[self.keyDelegate serverListKeyDown:e];
				}
				
				break;
			}
		}
	}
}

@end

#pragma mark -
#pragma mark User Interface for Mavericks

@implementation TVCServerListMavericksUserInterface
@end

#pragma mark -
#pragma mark User Interface for Vibrant Light in Yosemite

@implementation TVCServerListLightYosemiteUserInterface

+ (NSString *)privateMessageStatusIconFilename:(BOOL)isActive
{
	if (isActive) {
		return @"VibrantLightServerListViewPrivateMessageUserIconActive";
	} else {
		return @"VibrantLightServerListViewPrivateMessageUserIconInactive";
	}
}

+ (NSColor *)channelCellNormalItemTextColor
{
	return [NSColor colorWithCalibratedRed:0.232 green:0.232 blue:0.232 alpha:1.0];
}

+ (NSColor *)channelCellDisabledItemTextColor
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.5];
}

+ (NSColor *)channelCellHighlightedItemTextColor
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.414 blue:0.117 alpha:0.7];
}

+ (NSColor *)channelCellErroneousItemTextColor
{
	return [NSColor colorWithCalibratedRed:0.8203 green:0.0585 blue:0.0585 alpha:0.7];
}

+ (NSColor *)channelCellSelectedTextColorForActiveWindow
{
	return [NSColor whiteColor];
}

+ (NSColor *)channelCellSelectedTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.5];
}

+ (NSColor *)serverCellDisabledItemTextColor
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.3];
}

+ (NSColor *)serverCellNormalItemTextColor
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.5];
}

+ (NSColor *)serverCellSelectedTextColorForActiveWindow
{
	return [NSColor whiteColor];
}

+ (NSColor *)serverCellSelectedTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.5];
}

+ (NSFont *)messageCountBadgeFont
{
	return [NSFont systemFontOfSize:10.5];
}

+ (NSInteger)messageCountBadgeHeight
{
	return 14.0;
}

+ (NSInteger)messageCountBadgeMinimumWidth
{
	return 22.0;
}

+ (NSInteger)messageCountBadgePadding
{
	return 6.0;
}

+ (NSInteger)messageCountBadgeRightMargin
{
	return 3.0;
}

+ (NSInteger)channelCellTextFieldWithBadgeRightMargin
{
	return 8.0;
}

+ (NSColor *)messageCountNormalBadgeTextColor
{
	return [NSColor whiteColor];
}

+ (NSColor *)messageCountSelectedBadgeTextdColor
{
	return [NSColor colorWithCalibratedRed:0.232 green:0.232 blue:0.232 alpha:0.7];
}

+ (NSColor *)messageCountHighlightedBadgeTextColor
{
	return [NSColor whiteColor];
}

+ (NSColor *)messageCountNormalBadgeBackgroundColor
{
	return [NSColor colorWithCalibratedRed:0.232 green:0.232 blue:0.232 alpha:0.7];
}

+ (NSColor *)messageCountSelectedBadgeBackgroundColor
{
	return [NSColor whiteColor];
}

+ (NSColor *)messageCountHighlightedBadgeBackgroundColor
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.414 blue:0.117 alpha:0.7];
}

@end

#pragma mark -
#pragma mark User Interface for Vibrant Dark in Yosemite

@implementation TVCServerListDarkYosemiteUserInterface

+ (NSString *)privateMessageStatusIconFilename:(BOOL)isActive
{
	if (isActive) {
		return @"VibrantLightServerListViewPrivateMessageUserIconActive";
	} else {
		return @"VibrantLightServerListViewPrivateMessageUserIconInactive";
	}
}

+ (NSColor *)channelCellNormalItemTextColor
{
	return [NSColor colorWithCalibratedRed:0.232 green:0.232 blue:0.232 alpha:1.0];
}

+ (NSColor *)channelCellDisabledItemTextColor
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.5];
}

+ (NSColor *)channelCellHighlightedItemTextColor
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.414 blue:0.117 alpha:0.7];
}

+ (NSColor *)channelCellErroneousItemTextColor
{
	return [NSColor colorWithCalibratedRed:0.8203 green:0.0585 blue:0.0585 alpha:0.7];
}

+ (NSColor *)channelCellSelectedTextColorForActiveWindow
{
	return [NSColor whiteColor];
}

+ (NSColor *)channelCellSelectedTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.5];
}

+ (NSColor *)serverCellDisabledItemTextColor
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.3];
}

+ (NSColor *)serverCellNormalItemTextColor
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.5];
}

+ (NSColor *)serverCellSelectedTextColorForActiveWindow
{
	return [NSColor whiteColor];
}

+ (NSColor *)serverCellSelectedTextColorForInactiveWindow
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.0 blue:0.0 alpha:0.5];
}

+ (NSFont *)messageCountBadgeFont
{
	return [NSFont systemFontOfSize:10.5];
}

+ (NSInteger)messageCountBadgeHeight
{
	return 14.0;
}

+ (NSInteger)messageCountBadgeMinimumWidth
{
	return 22.0;
}

+ (NSInteger)messageCountBadgePadding
{
	return 6.0;
}

+ (NSInteger)messageCountBadgeRightMargin
{
	return 3.0;
}

+ (NSInteger)channelCellTextFieldWithBadgeRightMargin
{
	return 8.0;
}

+ (NSColor *)messageCountNormalBadgeTextColor
{
	return [NSColor whiteColor];
}

+ (NSColor *)messageCountSelectedBadgeTextdColor
{
	return [NSColor colorWithCalibratedRed:0.232 green:0.232 blue:0.232 alpha:0.7];
}

+ (NSColor *)messageCountHighlightedBadgeTextColor
{
	return [NSColor whiteColor];
}

+ (NSColor *)messageCountNormalBadgeBackgroundColor
{
	return [NSColor colorWithCalibratedRed:0.232 green:0.232 blue:0.232 alpha:0.7];
}

+ (NSColor *)messageCountSelectedBadgeBackgroundColor
{
	return [NSColor whiteColor];
}

+ (NSColor *)messageCountHighlightedBadgeBackgroundColor
{
	return [NSColor colorWithCalibratedRed:0.0 green:0.414 blue:0.117 alpha:0.7];
}

@end
