/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

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

#import <QuartzCore/QuartzCore.h>

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

		[self updateSelectionBackground:NO]; // Redraws disclosure triangle if one just appeared.
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

/* These drawing things are pretty sophisticaked so i do not even know how they work… */
- (void)reloadAllDrawings
{
	NSAssertReturn(_isDrawing == NO);

	_isDrawing = YES;

	for (NSInteger i = 0; i < [self numberOfRows]; i++) {
		[self updateDrawingForRow:i withSelectionUpdate:NO];
	}

	[self updateSelectionBackground:NO];
	
	[self setNeedsDisplay:YES];

	_isDrawing = NO;
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
	[self updateDrawingForRow:rowIndex withSelectionUpdate:YES];
}

- (void)updateDrawingForRow:(NSInteger)rowIndex withSelectionUpdate:(BOOL)updateSelection
{
	NSAssertReturn(rowIndex >= 0);

	id rowView = [self viewAtColumn:0 row:rowIndex makeIfNecessary:NO];

	if ([rowView isKindOfClass:[TVCServerListCellGroupItem class]] ||
		[rowView isKindOfClass:[TVCServerListCellChildItem class]])
	{
		NSRect cellFrame = [self frameOfCellAtColumn:0 row:rowIndex];

		if (updateSelection) {
			[self updateSelectionBackground:NO];
		}

		[rowView updateDrawing:cellFrame];
	}
}

- (void)updateSelectionBackground
{
	[self updateSelectionBackground:YES];
}

- (void)updateSelectionBackground:(BOOL)forceRedraw
{
	for (NSInteger i = 0; i < [self numberOfRows]; i++) {
		TVCServerListCell *rowView = [self viewAtColumn:0 row:i makeIfNecessary:NO];

		BOOL isGroup = [rowView isKindOfClass:[TVCServerListCellGroupItem class]];
		BOOL isChild = [rowView isKindOfClass:[TVCServerListCellChildItem class]];
		
		if (isGroup || isChild) {
			if (i == self.selectedRow) {
				[rowView updateSelectionBackgroundView];
			} else {
				if (rowView.backgroundImageCell.isHidden == NO) {
					[rowView.backgroundImageCell setHidden:YES];
					
					/* If our background was not hidden, then it means this view has a
					 history of being selected. Therefore, we will redraw it. */

					[self updateDrawingForRow:i withSelectionUpdate:NO];
				}
			}
			
			if (isGroup) {
				[rowView updateGroupDisclosureTriangle];
			}
		}
	}
}

- (void)updateBackgroundColor
{
	[self setBackgroundColor:self.properBackgroundColor];

	CALayer *scrollLayer = self.scrollView.contentView.layer;
	
	if (self.masterController.mainWindowIsActive) {
		if ([TPCPreferences invertSidebarColors] == NO) {
			[scrollLayer setBackgroundColor:[NSColor.sourceListBackgroundColorTop CGColor]];

			return;
		}
	}

	[scrollLayer setBackgroundColor:[self.properBackgroundColor CGColor]];
}

- (void)highlightSelectionInClipRect:(NSRect)clipRect
{
	/* Ignore this. */
}

- (NSScrollView *)scrollView
{
	return (id)self.superview.superview;
}

- (void)drawBackgroundInClipRect:(NSRect)clipRect
{
	if (self.masterController.mainWindowIsActive) {
		if ([TPCPreferences invertSidebarColors] == NO) {
			NSRect visibleRect = [self.scrollView documentVisibleRect];
			
			NSGradient *theGradient = [NSGradient sourceListBackgroundGradientColor];

			[theGradient drawInRect:visibleRect angle:90];

			return;
		}
	}

	[super drawBackgroundInClipRect:clipRect];
}

#pragma mark -
#pragma mark Events

- (NSMenu *)menuForEvent:(NSEvent *)e
{
	NSPoint p = [self convertPoint:e.locationInWindow fromView:nil];

	NSInteger i = [self rowAtPoint:p];

	if (i >= 0 && NSDissimilarObjects(i, self.selectedRow)) {
		[self selectItemAtIndex:i];
	} else if (i == -1) {
		return self.masterController.addServerMenu;
	}

	return self.menu;
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
				if ([self.keyDelegate respondsToSelector:@selector(serverListKeyDown:)]) {
					[self.keyDelegate serverListKeyDown:e];
				}
				
				break;
		}
	}
}

#pragma mark -
#pragma mark Frame

/* We handle frameOfCellAtColumn:row: to make it so our selected cell background
 draw stretches all the way from one end to the other of our list. */
- (NSRect)frameOfCellAtColumn:(NSInteger)column row:(NSInteger)row
{
	NSRect nrect = [super frameOfCellAtColumn:column row:row];

	nrect.size.width += 3;
	nrect.origin.x = 0;

	return nrect;
}

#pragma mark -
#pragma mark User Interface Design Elements

/* @_@ gawd, wut haf i gutten miself intu. */

- (NSColor *)properBackgroundColor
{
	if (self.masterController.mainWindowIsActive) {
		return [self activeWindowListBackgroundColor];
	} else {
		return [self inactiveWindowListBackgroundColor];
	}
}

- (NSColor *)activeWindowListBackgroundColor
{
	return [NSColor defineUserInterfaceItem:[NSColor clearColor]
							   invertedItem:[NSColor internalCalibratedRed:38.0 green:38.0 blue:38.0 alpha:1]];
}

- (NSColor *)inactiveWindowListBackgroundColor
{
	return [NSColor defineUserInterfaceItem:[NSColor internalCalibratedRed:237.0 green:237.0 blue:237.0 alpha:1]
							   invertedItem:[NSColor internalCalibratedRed:38.0 green:38.0 blue:38.0 alpha:1]];
}

- (NSFont *)messageCountBadgeFont
{
	return [RZFontManager() fontWithFamily:@"Helvetica" traits:NSBoldFontMask weight:15 size:10.5];
}

- (NSFont *)serverCellFont
{
	return [NSFont fontWithName:@"LucidaGrande-Bold" size:12.0];
}

- (NSFont *)normalChannelCellFont
{
	return [NSFont fontWithName:@"LucidaGrande" size:11.0];
}

- (NSFont *)selectedChannelCellFont
{
	return [NSFont fontWithName:@"LucidaGrande-Bold" size:11.0];
}

- (NSInteger)channelCellTextFieldLeftMargin
{
	/* Keep this in sync with the interface builder file. */

	return 38.0;
}

- (NSInteger)messageCountBadgeHeight
{
	return 14.0;
}

- (NSInteger)messageCountBadgePadding
{
	return 5.0;
}

- (NSInteger)messageCountBadgeMinimumWidth
{
	return 22.0;
}

- (NSInteger)messageCountBadgeRightMargin
{
	return 5.0;
}

- (NSColor *)messageCountBadgeHighlightBackgroundColor
{
	return [NSColor defineUserInterfaceItem:[NSColor internalCalibratedRed:210 green:15 blue:15 alpha:1]
							   invertedItem:[NSColor internalCalibratedRed:141.0 green:0.0 blue:0.0  alpha:1]];
}

- (NSColor *)messageCountBadgeAquaBackgroundColor
{
	return [NSColor defineUserInterfaceItem:[NSColor internalCalibratedRed:152 green:168 blue:202 alpha:1]
							   invertedItem:[NSColor internalCalibratedRed:48.0 green:48.0 blue:48.0 alpha:1]];
}

- (NSColor *)messageCountBadgeGraphtieBackgroundColor
{
	return [NSColor defineUserInterfaceItem:[NSColor internalCalibratedRed:132 green:147 blue:163 alpha:1]
							   invertedItem:[NSColor internalCalibratedRed:48.0 green:48.0 blue:48.0 alpha:1]];
}

- (NSColor *)messageCountBadgeSelectedBackgroundColor
{
	return [NSColor defineUserInterfaceItem:[NSColor whiteColor]
							   invertedItem:[NSColor darkGrayColor]];
}

- (NSColor *)messageCountBadgeShadowColor
{
	return [NSColor defineUserInterfaceItem:[NSColor colorWithCalibratedWhite:1.00 alpha:0.60]
							   invertedItem:[NSColor internalCalibratedRed:60.0 green:60.0 blue:60.0 alpha:1]];
}

- (NSColor *)messageCountBadgeNormalTextColor
{
	return [NSColor whiteColor];
}

- (NSColor *)messageCountBadgeSelectedTextColor
{
	return [NSColor defineUserInterfaceItem:[NSColor internalCalibratedRed:158 green:169 blue:197 alpha:1]
							   invertedItem:[NSColor whiteColor]];
}

- (NSColor *)serverCellNormalTextColor
{
	return [NSColor defineUserInterfaceItem:[NSColor outlineViewHeaderTextColor]
							   invertedItem:[NSColor internalCalibratedRed:225.0 green:224.0 blue:224.0 alpha:1]];
}

- (NSColor *)serverCellDisabledTextColor
{
	return [NSColor defineUserInterfaceItem:[NSColor outlineViewHeaderDisabledTextColor]
							   invertedItem:[NSColor internalCalibratedRed:225.0 green:224.0 blue:224.0 alpha:0.7]];
}

- (NSColor *)serverCellSelectedTextColorForActiveWindow
{
	return [NSColor defineUserInterfaceItem:[NSColor whiteColor]
							   invertedItem:[NSColor internalCalibratedRed:36.0 green:36.0 blue:36.0 alpha:1]];
}

- (NSColor *)serverCellSelectedTextColorForInactiveWindow
{
	return [NSColor defineUserInterfaceItem:[NSColor whiteColor]
							   invertedItem:[NSColor internalCalibratedRed:36.0 green:36.0 blue:36.0 alpha:1]];
}

- (NSColor *)serverCellNormalTextShadowColorForActiveWindow
{
	return [NSColor defineUserInterfaceItem:[NSColor colorWithCalibratedWhite:1.00 alpha:1.00]
							   invertedItem:[NSColor colorWithCalibratedWhite:0.00 alpha:0.90]];
}

- (NSColor *)serverCellNormalTextShadowColorForInactiveWindow
{
	return [NSColor defineUserInterfaceItem:[NSColor colorWithCalibratedWhite:1.00 alpha:1.00]
							   invertedItem:[NSColor colorWithCalibratedWhite:0.00 alpha:0.90]];
}

- (NSColor *)serverCellSelectedTextShadowColorForActiveWindow
{
	return [NSColor defineUserInterfaceItem:[NSColor colorWithCalibratedWhite:0.00 alpha:0.30]
							   invertedItem:[NSColor colorWithCalibratedWhite:1.00 alpha:0.30]];
}

- (NSColor *)serverCellSelectedTextShadowColorForInactiveWindow
{
	return [NSColor defineUserInterfaceItem:[NSColor colorWithCalibratedWhite:0.00 alpha:0.20]
							   invertedItem:[NSColor colorWithCalibratedWhite:1.00 alpha:0.30]];
}

- (NSColor *)channelCellNormalTextColor
{
	return [NSColor defineUserInterfaceItem:[NSColor blackColor]
							   invertedItem:[NSColor internalCalibratedRed:225.0 green:224.0 blue:224.0 alpha:1]];
}

- (NSColor *)channelCellSelectedTextColorForActiveWindow
{
	return [NSColor defineUserInterfaceItem:[NSColor whiteColor]
							   invertedItem:[NSColor internalCalibratedRed:36.0 green:36.0 blue:36.0 alpha:1]];
}

- (NSColor *)channelCellSelectedTextColorForInactiveWindow
{
	return [NSColor defineUserInterfaceItem:[NSColor whiteColor]
							   invertedItem:[NSColor internalCalibratedRed:36.0 green:36.0 blue:36.0 alpha:1]];
}

- (NSColor *)channelCellNormalTextShadowColor
{
	return [NSColor defineUserInterfaceItem:[NSColor colorWithSRGBRed:1.0 green:1.0 blue:1.0 alpha:0.6]
							   invertedItem:[NSColor colorWithCalibratedWhite:0.00 alpha:0.90]];
}

- (NSColor *)channelCellSelectedTextShadowColorForActiveWindow
{
	return [NSColor defineUserInterfaceItem:[NSColor colorWithCalibratedWhite:0.00 alpha:0.48]
							   invertedItem:[NSColor colorWithCalibratedWhite:1.00 alpha:0.30]];
}

- (NSColor *)channelCellSelectedTextShadowColorForInactiveWindow
{
	return [NSColor defineUserInterfaceItem:[NSColor colorWithCalibratedWhite:0.00 alpha:0.30]
							   invertedItem:[NSColor colorWithCalibratedWhite:1.00 alpha:0.30]];
}

- (NSColor *)graphiteTextSelectionShadowColor
{
	return [NSColor internalCalibratedRed:17 green:73 blue:126 alpha:1.00];
}

#pragma mark -
#pragma mark Utilities

- (NSImage *)disclosureTriangleInContext:(BOOL)up selected:(BOOL)selected
{
	BOOL invertedColors = [TPCPreferences invertSidebarColors];

	if (invertedColors) {
		if (up) {
			if (selected) {
				return [NSImage imageNamed:@"DarkServerListViewDisclosureUpSelected"];
			} else {
				return [NSImage imageNamed:@"DarkServerListViewDisclosureUp"];
			}
		} else {
			if (selected) {
				return [NSImage imageNamed:@"DarkServerListViewDisclosureDownSelected"];
			} else {
				return [NSImage imageNamed:@"DarkServerListViewDisclosureDown"];
			}
		}
	} else {
		if (up) {
			return self.defaultDisclosureTriangle;
		} else {
			return self.alternateDisclosureTriangle;
		}
	}
}

- (NSString *)privateMessageStatusIconFilename:(BOOL)selected
{
	return [NSColor defineUserInterfaceItem:@"NSUser" invertedItem:@"DarkServerListViewSelectedPrivateMessageUser" withOperator:(selected == NO)];
}

@end

#pragma mark -
#pragma mark Scroll View Clip View

@implementation TVCServerListScrollClipView

- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		self.layer = [CAScrollLayer layer];

		self.wantsLayer = YES;
		self.layerContentsRedrawPolicy = NSViewLayerContentsRedrawNever;
		
		return self;
	}

	return nil;
}

@end

#pragma mark -
#pragma mark Scroll View

@implementation TVCServerListScrollView

- (void)swapClipView
{
	self.wantsLayer = YES;
	
    id documentView = self.documentView;

	TVCServerListScrollClipView *clipView = [[TVCServerListScrollClipView alloc] initWithFrame:self.contentView.frame];

	self.contentView = clipView;
	self.documentView = documentView;
}

- (id)initWithFrame:(NSRect)frame
{
	if ((self = [super initWithFrame:frame])) {
		[self swapClipView];

		return self;
	}

	return nil;
}

- (void)awakeFromNib
{
    [super awakeFromNib];

    if ([self.contentView isKindOfClass:[TVCServerListScrollClipView class]] == NO) {
        [self swapClipView];
    }
}

@end
