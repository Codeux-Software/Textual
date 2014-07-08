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

@interface TVCAnimatedContentNavigationOutlineView ()
@property (nonatomic, assign) BOOL navgiationTreeIsAnimating;
@property (nonatomic, assign) NSInteger lastSelectedNavigationItem;
@property (nonatomic, assign) NSInteger currentSelectedNavigationItem;
@end

@implementation TVCAnimatedContentNavigationOutlineView

#pragma mark -
#pragma mark Basic Class

- (void)awakeFromNib
{
	self.navgiationTreeIsAnimating = NO;

	self.lastSelectedNavigationItem = -1;
	self.currentSelectedNavigationItem = -1;
	
	[self setDelegate:self];
	[self setDataSource:self];
}

- (void)startAtSelectionIndex:(NSInteger)startingSelection
{
	self.lastSelectedNavigationItem = startingSelection;
	self.currentSelectedNavigationItem = startingSelection;
	
	[self selectItemAtIndex:startingSelection];
}

#pragma mark -
#pragma mark NSOutlineViewDelegate Delegates

- (NSInteger)outlineView:(NSOutlineView *)sender numberOfChildrenOfItem:(NSDictionary *)item
{
	if (item) {
		return [item[@"children"] count];
	} else {
		return [self.navigationTreeMatrix count];
	}
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(NSDictionary *)item
{
	if (item) {
		return item[@"children"][index];
	} else {
		return self.navigationTreeMatrix[index];
	}
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(NSDictionary *)item
{
	return ([item boolForKey:@"blockCollapse"] == NO);
}

- (BOOL)outlineView:(NSOutlineView *)sender isItemExpandable:(NSDictionary *)item
{
	return [item containsKey:@"children"];
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(NSDictionary *)item
{
	return item[@"name"];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	if (self.navgiationTreeIsAnimating) {
		return NO;
	} else {
		return ([item containsKey:@"children"] == NO);
	}
}

- (id)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(NSDictionary *)item
{
	NSTableCellView *newView = [outlineView makeViewWithIdentifier:@"navEntry" owner:self];
	
	[[newView textField] setStringValue:item[@"name"]];
	
	return newView;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSInteger selectedRow = [self selectedRow];
	
	NSDictionary *navItem = [self itemAtRow:selectedRow];
	
	self.lastSelectedNavigationItem = self.currentSelectedNavigationItem;
	
	self.currentSelectedNavigationItem = selectedRow;
	
	[self presentView:navItem[@"view"]];
}

- (NSRect)currentWindowFrame
{
	return [self.parentWindow frame];
}

- (void)presentView:(NSView *)newView
{
	/* Determine direction. */
	BOOL isGoingDown = NO;
	
	if (self.currentSelectedNavigationItem > self.lastSelectedNavigationItem) {
		isGoingDown = YES;
	}
	
	BOOL invertedScrollingDirection = [RZUserDefaults() boolForKey:@"com.apple.swipescrolldirection"];
	
	if (invertedScrollingDirection) {
		if (isGoingDown) {
			isGoingDown = NO;
		} else {
			isGoingDown = YES;
		}
	}
	
	self.navgiationTreeIsAnimating = YES;
	
	/* Set view frame. */
	NSRect newViewFinalFrame = [newView frame];
	
	newViewFinalFrame.origin.x = 0;
	newViewFinalFrame.origin.y = 0;
	
	newViewFinalFrame.size.width = self.contentViewPreferredWidth;
	
	if (newViewFinalFrame.size.height < self.contentViewPreferredHeight) {
		newViewFinalFrame.size.height = self.contentViewPreferredHeight;
	}
	
	/* Set frame animation will start at. */
	NSRect newViewAnimationFrame = newViewFinalFrame;
	
	if (isGoingDown) {
		newViewAnimationFrame.origin.y += newViewAnimationFrame.size.height;
	} else {
		newViewAnimationFrame.origin.y -= newViewAnimationFrame.size.height;
	}
	
	[newView setFrame:newViewAnimationFrame];
	
	/* Update window size. */
	NSRect contentViewFrame = [self.contentView frame];
	
	BOOL contentSizeDidntChange =  (contentViewFrame.size.height == newViewFinalFrame.size.height);
	BOOL windowWillBecomeSmaller = (contentViewFrame.size.height >  newViewFinalFrame.size.height);
	
	/* Special condition to allow for smoother animations when going up
	 with a window which is resizing to a smaller size. */
	if (isGoingDown && windowWillBecomeSmaller) {
		isGoingDown = NO;
	}
	
	/* Set window frame. */
	NSRect windowFrame = [self currentWindowFrame];
	
	if (contentSizeDidntChange == NO) {
		windowFrame.size.height = (self.contentViewPadding + newViewFinalFrame.size.height);
		
		windowFrame.origin.y = (NSMaxY([self currentWindowFrame]) - windowFrame.size.height);
		
		[self.window setFrame:windowFrame display:YES animate:YES];
	}
	
	/* Add new frame. */
	[self.contentView addSubview:newView];
	
	/* Update content frame. */
	if (contentSizeDidntChange == NO) {
		contentViewFrame.size.height = newViewFinalFrame.size.height;
	}
	
	/* Cancel any previous animation resets. */
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timedRemoveFrame:) object:newView];
	
	/* Begin animation. */
	[RZAnimationCurrentContext() setDuration:0.7];
	
	/* Find existing views. */
	/* If count is 0, then that means preferences just launched
	 and we have not added anything to our window yet. */
	NSArray *subviews = [self.contentView subviews];
	
	NSInteger subviewCount = [subviews count];
	
	if (subviewCount > 1) {
		NSView *oldView = [self.contentView subviews][0];
		
		/* If the number of visible views is more than 2 (the one we added and the old),
		 then we erase the old views because the user could be clicking the navigation
		 list fast which means the old views would stick until animations complete. */
		if (subviewCount > 2) {
			for (NSInteger i = 2; i < subviewCount; i++) {
				[subviews[i] removeFromSuperview];
			}
		}
		
		NSRect oldViewAnimationFrame = [oldView frame]; // Set frame animation will end at.
		
		if (isGoingDown) {
			oldViewAnimationFrame.origin.y = -(windowFrame.size.height); // No way anything will be there…
		} else {
			oldViewAnimationFrame.origin.y =   windowFrame.size.height; // No way anything will be there…
		}
		
		[oldView.animator setAlphaValue:0.0];
		[oldView.animator setFrame:oldViewAnimationFrame];
		
		[newView.animator setAlphaValue:1.0];
		[newView.animator setFrame:newViewFinalFrame];
		
		[self performSelector:@selector(timedRemoveFrame:) withObject:oldView afterDelay:0.3];
	} else {
		[newView setFrame:newViewFinalFrame];
		
		self.navgiationTreeIsAnimating = NO;
	}
	
	[self.window recalculateKeyViewLoop];
}

- (void)timedRemoveFrame:(NSView *)oldView
{
	self.navgiationTreeIsAnimating = NO;
	
	[oldView removeFromSuperview];
}

@end
