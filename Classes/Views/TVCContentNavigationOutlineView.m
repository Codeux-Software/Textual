/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

#import "NSViewHelper.h"
#import "TVCContentNavigationOutlineViewPrivate.h"

NS_ASSUME_NONNULL_BEGIN

@interface TVCContentNavigationOutlineView ()
@property (nonatomic, strong) IBOutlet NSView *contentView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentViewHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *contentViewWidthConstraint;
@property (nonatomic, weak) id lastSelectionWeakRef;
@property (readonly, nullable) id parentOfSelectedItem;
@end

@implementation TVCContentNavigationOutlineView

#pragma mark -
#pragma mark Basic Class

- (void)awakeFromNib
{
	self.dataSource = (id)self;
	self.delegate = (id)self;

	self.doubleAction = @selector(outlineViewDoubleClicked:);
}

- (void)navigateTo:(NSUInteger)selectionIndex
{
	for (id groupItem in self.groupItems) {
		NSArray *childItems = [self itemsFromParentGroup:groupItem];

		id childItem = [childItems objectPassingTest:^BOOL(NSDictionary<NSString *, id> *attributes, NSUInteger index, BOOL *stop) {
			return (selectionIndex == [attributes[@"index"] integerValue]);
		}];

		if (childItem == nil) {
			continue;
		}

		[self expandItem:groupItem];

		[self selectItemAtIndex:[self rowForItem:childItem]];

		return;
	}
}

#pragma mark -
#pragma mark Collapse/Expand Logic

- (nullable id)parentOfSelectedItem
{
	if (self.lastSelectionWeakRef == nil) {
		return nil;
	}

	id parentItem = [self parentForItem:self.lastSelectionWeakRef];

	return parentItem;
}

- (void)outlineViewDoubleClicked:(id)sender
{
	if (self.expandParentOnDoubleClick == NO) {
		return;
	}

	NSInteger clickedRow = self.clickedRow;

	if (clickedRow < 0) {
		return;
	}

	id itemAtRow = [self itemAtRow:clickedRow];

	if ([self isGroupItem:itemAtRow] == NO) {
		return;
	}

	[self expandItem:itemAtRow];
}

#pragma mark -
#pragma mark NSOutlineViewDelegate Delegates

- (NSInteger)outlineView:(NSOutlineView *)sender numberOfChildrenOfItem:(nullable id)item
{
	if (item) {
		return [item[@"children"] count];
	}

	return self.navigationTreeMatrix.count;
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(nullable id)item
{
	if (item) {
		return item[@"children"][index];
	}

	return self.navigationTreeMatrix[index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldCollapseItem:(id)item
{
	return ([item boolForKey:@"blockCollapse"] == NO);
}

- (BOOL)outlineView:(NSOutlineView *)sender isItemExpandable:(id)item
{
	return [item containsKey:@"children"];
}

- (void)outlineViewItemDidExpand:(NSNotification *)notification
{
	id parentItem = self.parentOfSelectedItem;

	id itemCrushed = notification.userInfo[@"NSObject"];

	if (itemCrushed != parentItem) {
		return;
	}

	if ([self isItemExpanded:parentItem] == NO) {
		return;
	}

	NSInteger childIndex = [self rowForItem:self.lastSelectionWeakRef];

	if (childIndex >= 0) {
		[self selectItemAtIndex:childIndex];
	}
}

- (nullable id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(nullable NSTableColumn *)tableColumn byItem:(nullable id)item
{
	return item[@"name"];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView shouldSelectItem:(id)item
{
	return ([item containsKey:@"children"] == NO);
}

- (nullable id)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(nullable NSTableColumn *)tableColumn item:(id)item
{
	NSTableCellView *newView = [outlineView makeViewWithIdentifier:@"navEntry" owner:self];

	return newView;
}

- (void)outlineViewSelectionDidChange:(NSNotification *)notification
{
	NSInteger selectedRow = self.selectedRow;

	if (selectedRow < 0) {
		return;
	}

	NSDictionary *navigationItem = [self itemAtRow:selectedRow];

	self.lastSelectionWeakRef = navigationItem;

	[self presentView:navigationItem[@"view"]];

	id firstResponder = navigationItem[@"firstResponder"];

	if (firstResponder) {
		[self.window makeFirstResponder:firstResponder];
	}
}

- (void)presentView:(NSView *)newView
{
	[self.contentView attachSubview:newView
			adjustedWidthConstraint:self.contentViewWidthConstraint
		   adjustedHeightConstraint:self.contentViewHeightConstraint];
}

@end

NS_ASSUME_NONNULL_END
