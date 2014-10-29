/* ********************************************************************* 
				  _____         _               _
				 |_   _|____  _| |_ _   _  __ _| |
				   | |/ _ \ \/ / __| | | |/ _` | |
				   | |  __/>  <| |_| |_| | (_| | |
				   |_|\___/_/\_\\__|\__,_|\__,_|_|

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
    * Neither the name of Textual and/or Codeux Software, nor the names of 
      its contributors may be used to endorse or promote products derived 
      from this software without specific prior written permission.

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

/* This outline view used to be animated. See git history. */
@implementation TVCAnimatedContentNavigationOutlineView

#pragma mark -
#pragma mark Basic Class

- (void)awakeFromNib
{
	[self setDelegate:self];
	[self setDataSource:self];
}

- (void)startAtSelectionIndex:(NSInteger)startingSelection
{
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
	return ([item containsKey:@"children"] == NO);
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

	[self presentView:navItem[@"view"]];
	
	id firstResponder = navItem[@"firstResponder"];
	
	if (firstResponder) {
		[self.parentWindow makeFirstResponder:firstResponder];
	}
}

- (void)presentView:(NSView *)newView
{
	/* Calculate view frame. */
	NSRect newViewFinalFrame = [newView frame];

	newViewFinalFrame.origin.x = 0;
	newViewFinalFrame.origin.y = 0;

	newViewFinalFrame.size.width = self.contentViewPreferredWidth;

	if (newViewFinalFrame.size.height < self.contentViewPreferredHeight) {
		newViewFinalFrame.size.height = self.contentViewPreferredHeight;
	}

	[newView setFrame:newViewFinalFrame];

	/* Update window size. */
	NSRect windowFrame = [self.parentWindow frame];

	windowFrame.size.height = (self.contentViewPadding + newViewFinalFrame.size.height);

	windowFrame.origin.y = (NSMaxY([self.parentWindow frame]) - windowFrame.size.height);

	[self.parentWindow setFrame:windowFrame display:YES animate:NO];

	/* Add new frame. */
	if ([[self.contentView subviews] count] == 1) {
		[[self.contentView subviews][0] removeFromSuperview];
	}

	[self.contentView addSubview:newView];

	[self.parentWindow recalculateKeyViewLoop];
}

@end
