/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
        Please see Acknowledgements.pdf for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

    * Redistributions of source code must retain the above copyright
      notice, this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.
    * Neither the name of Textual and/or "Codeux Software, LLC", nor the 
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

#import "TVCMainWindowPrivate.h"

@interface TVCMainWindowChannelViewSubview ()
@property (nonatomic, assign) NSInteger itemIndex;
@property (nonatomic, readwrite, assign) BOOL overlayVisible;
@property (nonatomic, copy) NSString *treeUUID;
@property (nonatomic, weak) NSView *webView;
@property (nonatomic, strong) TVCMainWindowChannelViewSubviewOverlayView *overlayView;

- (void)resetSubviews;
@end

@interface TVCMainWindowChannelView ()
@property (nonatomic, assign) BOOL isMovingDividers;
@property (nonatomic, assign) NSInteger itemIndexSelected;

- (void)selectionChangeTo:(NSInteger)itemIndex;
@end

@implementation TVCMainWindowChannelView

NSComparisonResult sortSubviews(id firstView, id secondView, void *context)
{
	NSInteger itemIndex1 = [firstView itemIndex];
	NSInteger itemIndex2 = [secondView itemIndex];

	if (itemIndex1 < itemIndex2) {
		return NSOrderedAscending;
	} else if (itemIndex1 > itemIndex2) {
		return NSOrderedDescending;
	}

	return NSOrderedSame;
}

- (void)awakeFromNib
{
	[self setDelegate:self];
}

- (void)resetSubviews
{
	NSArray *subviews = [[self subviews] copy];

	for (NSView *subview in subviews) {
		[subview removeFromSuperview];
	}
}

- (void)populateSubviews
{
	/* Get list of views selected by the user */
	NSArray *selectedItems = [mainWindow() selectedItems];

	NSInteger selectedItemsCount = [selectedItems count];

	if (selectedItemsCount == 0) {
		[self resetSubviews];

		self.itemIndexSelected = NSNotFound;

		return;
	}

	/* Make a list of subviews that already exist to compare when adding
	 or removing views so that we do not have to destroy entire backing. */
	NSMutableDictionary *subviews = nil;

	for (TVCMainWindowChannelViewSubview *subview in [self subviews]) {
		if (subviews == nil) {
			subviews = [NSMutableDictionary dictionary];
		}

		[subviews setObject:subview forKey:[subview treeUUID]];
	}

	/* Once selectedItems is processed, the value of subviewsUnclaimed will
	 be subviews that are no longer selected */
	NSMutableDictionary *subviewsUnclaimed = nil;

	if (subviews) {
		subviewsUnclaimed = [subviews mutableCopy];
	}

	/* Enumerate views that the user has selected */
	IRCTreeItem *itemSelected = [mainWindow() selectedItem];

	__block NSInteger itemIndexSelected = 0;

	[selectedItems enumerateObjectsUsingBlock:^(id item, NSUInteger index, BOOL *stop) {
		NSString *itemIdentifier = [item treeUUID];

		TVCMainWindowChannelViewSubview *subview = nil;

		BOOL subviewIsNew = YES;

		if (subviews) {
			subview = subviews[itemIdentifier];

			if (subview) {
				subviewIsNew = NO;

				[subviewsUnclaimed removeObjectForKey:itemIdentifier];
			}
		}

		if (subview == nil) {
			subview = [self subviewForItem:item];
		}

		NSView *webView = [self webViewForItem:item];

		[subview setWebView:webView];

		[subview setItemIndex:index];

		if (item == itemSelected) {
			itemIndexSelected = index;

			[subview setOverlayVisible:NO];
		} else {
			[subview setOverlayVisible:YES];
		}

		[subview setTreeUUID:itemIdentifier];

		if (subviewIsNew) {
			[self addSubview:subview];
		}
	}];

	self.itemIndexSelected = itemIndexSelected;

	/* Remove subviews that are no longer selected */
	if (subviewsUnclaimed) {
		for (NSString *itemIdentifier in subviewsUnclaimed) {
			TVCMainWindowChannelViewSubview *subview = subviewsUnclaimed[itemIdentifier];

			[subview removeFromSuperview];
		}

		subviewsUnclaimed = nil;
	}

	/* Sort views */
	if (subviews) {
		[self sortSubviewsUsingFunction:sortSubviews context:nil];

		subviews = nil;
	}

	/* Size views */
	[self positionDividersProportionally];
}

- (void)selectionChangeTo:(NSInteger)itemIndex
{
	NSArray *presentedViews = [mainWindow() selectedItems];

	NSArray *subviews = [[self subviews] copy];

	NSInteger itemIndexSelected = self.itemIndexSelected;

	IRCTreeItem *newItem = presentedViews[itemIndex];

	TVCMainWindowChannelViewSubview *newItemView = subviews[itemIndex];
	TVCMainWindowChannelViewSubview *oldItemView = subviews[itemIndexSelected];

	[newItemView setOverlayVisible:NO];
	[oldItemView setOverlayVisible:YES];

	self.itemIndexSelected = itemIndex;

	[mainWindow() channelViewSelectionChangeTo:newItem];
}

- (NSView *)webViewForItem:(IRCTreeItem *)item
{
	TVCLogView *backingView = [[item viewController] backingView];

	return [backingView webView];
}

- (TVCMainWindowChannelViewSubview *)subviewForItem:(IRCTreeItem *)item
{
	  TVCMainWindowChannelViewSubview *overlayView =
	[[TVCMainWindowChannelViewSubview alloc] initWithFrame:NSZeroRect];

	return overlayView;
}

- (void)positionDividersProportionally
{
	NSInteger subviewCount = [[self subviews] count];

	NSAssertReturn(subviewCount > 1);

	NSRect splitViewFrame = [self frame];

	CGFloat dividerThickness = [self dividerThickness];

	NSInteger subviewHeight = ((splitViewFrame.size.height / subviewCount) -
							   (dividerThickness * (subviewCount - 1)));

	self.isMovingDividers = YES;

	for (NSInteger i = 0; i < subviewCount; i++) {
		NSInteger currentPosition = (subviewHeight * (i + 1));

		[self setPosition:currentPosition ofDividerAtIndex:i];
	}

	self.isMovingDividers = NO;
}

- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex
{
	/* This magic number is also in -setWebView: further down this source file.
	 If you modify the number here, then make sure you modify it there too. */
#define _minimumHeight		55.0

	if (self.isMovingDividers) {
		return proposedPosition;
	}

	if (dividerIndex > 0) {
		NSArray *subviews = [self subviews];

		NSView *upperView = subviews[(dividerIndex - 1)];

		NSRect upperViewFrame = [upperView frame];

		CGFloat minCoordinate = (NSMaxY(upperViewFrame) + [self dividerThickness] + _minimumHeight);

		if (proposedPosition < minCoordinate) {
			proposedPosition = minCoordinate;
		}
	}

	if (proposedPosition < _minimumHeight) {
		return _minimumHeight;
	}

	return proposedPosition;

#undef _minimumHeight
}

- (NSLayoutPriority)holdingPriorityForSubviewAtIndex:(NSInteger)subviewIndex
{
	return 1.0;
}

- (BOOL)splitView:(NSSplitView *)splitView canCollapseSubview:(NSView *)subview
{
	return NO;
}

- (CGFloat)dividerThickness
{
	return 2.0;
}

- (void)drawDividerInRect:(NSRect)rect
{
	NSColor *dividerColor = TVCMainWindowSplitViewDividerColor;

	if ([TPCPreferences invertSidebarColors]) {
		dividerColor = [dividerColor invertedColor];
	}

	[dividerColor set];

	NSRectFill(rect);
}

@end

#pragma mark -
#pragma mark Overlay View

@implementation TVCMainWindowChannelViewSubview

- (instancetype)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect])) {
		[self setTranslatesAutoresizingMaskIntoConstraints:NO];

		return self;
	}

	return nil;
}

- (void)resetSubviews
{
	NSArray *subviews = [[self subviews] copy];

	for (NSView *subview in subviews) {
		[subview removeFromSuperview];
	}
}

- (void)setWebView:(NSView *)webView
{
	if (_webView != webView) {
		_webView = webView;

		[self addSubview:webView];

		[self addConstraints:
		 [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[webView]-0-|"
												 options:NSLayoutFormatDirectionLeadingToTrailing
												 metrics:nil
												   views:NSDictionaryOfVariableBindings(webView)]];

		[self addConstraints:
		 [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[webView(>=55)]-0-|"
												 options:NSLayoutFormatDirectionLeadingToTrailing
												 metrics:nil
												   views:NSDictionaryOfVariableBindings(webView)]];
	}
}

- (void)addOverlayView
{
	  TVCMainWindowChannelViewSubviewOverlayView *overlayView =
	[[TVCMainWindowChannelViewSubviewOverlayView alloc] initWithFrame:NSZeroRect];

	[overlayView setTranslatesAutoresizingMaskIntoConstraints:NO];

	[self addSubview:overlayView];

	[self addConstraints:
	 [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-0-[overlayView]-0-|"
											 options:NSLayoutFormatDirectionLeadingToTrailing
											 metrics:nil
											   views:NSDictionaryOfVariableBindings(overlayView)]];

	[self addConstraints:
	 [NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[overlayView]-0-|"
											 options:NSLayoutFormatDirectionLeadingToTrailing
											 metrics:nil
											   views:NSDictionaryOfVariableBindings(overlayView)]];

	self.overlayView = overlayView;
}

- (void)setOverlayVisible:(BOOL)overlayVisible
{
	if (_overlayVisible != overlayVisible) {
		_overlayVisible = overlayVisible;

		if (_overlayVisible == NO) {
			if ( self.overlayView) {
				[self.overlayView removeFromSuperview];
			}
		} else {
			[self addOverlayView];
		}
	}
}

- (void)mouseDown
{
	[[mainWindow() channelView] selectionChangeTo:[self itemIndex]];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	if (self.overlayVisible) {
		[self mouseDown];
	} else {
		[super mouseDown:theEvent];
	}
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	if (self.overlayVisible) {
		[self mouseDown];
	} else {
		[super rightMouseDown:theEvent];
	}
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
	if (self.overlayVisible) {
		[self mouseDown];
	} else {
		[super otherMouseDown:theEvent];
	}
}

- (NSView *)hitTest:(NSPoint)aPoint
{
	if (NSPointInRect(aPoint, [self frame]) == NO) {
		return nil;
	}

	if (self.overlayVisible) {
		return self.overlayView;
	} else {
		return [super hitTest:aPoint];
	}
}

@end

@implementation TVCMainWindowChannelViewSubviewOverlayView

- (void)mouseDown:(NSEvent *)theEvent
{
	[[self superview] mouseDown:theEvent];
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
	[[self superview] rightMouseDown:theEvent];
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
	[[self superview] otherMouseDown:theEvent];
}

- (void)drawRect:(NSRect)dirtyRect
{
	if ([self needsToDrawRect:dirtyRect] == NO) {
		return;
	}

	if ([TPCPreferences invertSidebarColors]) {
		[[NSColor colorWithCalibratedWhite:0.0 alpha:0.4] set];
	} else {
		[[NSColor colorWithCalibratedWhite:0.0 alpha:0.2] set];
	}

	[NSBezierPath fillRect:dirtyRect];
}

- (NSView *)hitTest:(NSPoint)aPoint
{
	return self;
}

@end
