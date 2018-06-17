/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2016 Codeux Software, LLC & respective contributors.
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

#import "TXGlobalModels.h"
#import "TLOLanguagePreferences.h"
#import "IRCClient.h"
#import "IRCChannel.h"
#import "TDCChannelSpotlightControllerInternal.h"
#import "TDCChannelSpotlightControllerPanelPrivate.h"
#import "TDCChannelSpotlightSearchResultPrivate.h"
#import "TDCChannelSpotlightSearchResultsTablePrivate.h"

NS_ASSUME_NONNULL_BEGIN

#define KeyboardShortcutFieldTopConstraintSelected				13.0
#define KeyboardShortcutFieldTopConstraintDeselected			11.0

@implementation TDCChannelSpotlightSearchResultCellView

- (BOOL)wantsLayer
{
	return YES;
}

- (NSViewLayerContentsRedrawPolicy)layerContentsRedrawPolicy
{
	return NSViewLayerContentsRedrawOnSetNeedsDisplay;
}

- (void)updateLayer
{
	TDCChannelSpotlightSearchResultRowView *rowView = (id)self.superview;

	[self updateTextFieldTextColorIsSelected:rowView.isSelected];

	[self willChangeValueForKey:@"keyboardShortcut"];
	[self didChangeValueForKey:@"keyboardShortcut"];
}

- (void)updateTextFieldTextColorIsSelected:(BOOL)isSelected
{
	if (isSelected == NO)
	{
		self.channelNameField.textColor = [self channelNameTextColorDeselected];

		self.keyboardShortcutField.textColor = [self keyboardShortcutTextColorDeselected];
		self.keyboardShortcutFieldTopConstraint.constant = KeyboardShortcutFieldTopConstraintDeselected;

		self.unreadCountDescriptionField.textColor = [self unreadCountDescriptionTextColorDeselected];
	}
	else
	{
		self.channelNameField.textColor = [self channelNameTextColorSelected];

		self.keyboardShortcutField.textColor = [self keyboardShortcutTextColorSelected];
		self.keyboardShortcutFieldTopConstraint.constant = KeyboardShortcutFieldTopConstraintSelected;

		self.unreadCountDescriptionField.textColor = [self unreadCountDescriptionTextColorSelected];
	}
}

- (NSAttributedString *)channelName
{
	TDCChannelSpotlightSearchResult *searchResult = self.objectValue;

	if (searchResult == nil) {
		return [NSAttributedString attributedString];
	}

	static NSMutableParagraphStyle *paragraphStyle = nil;

	if (paragraphStyle == nil) {
		paragraphStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];

		paragraphStyle.lineBreakMode = NSLineBreakByTruncatingTail;
	}

	NSString *channelName = searchResult.channel.name;

	NSFont *channelNameFieldFont = self.channelNameField.font;

	NSMutableAttributedString *resultString =
	[NSMutableAttributedString
	 mutableAttributedStringWithString:TXTLS(@"TDCChannelSpotlightController[1001]", channelName)
							attributes:@{
								NSFontAttributeName : channelNameFieldFont,
								NSParagraphStyleAttributeName : paragraphStyle
							}];

	TDCChannelSpotlightController *controller = searchResult.controller;

	NSString *searchString = controller.searchString;

	[resultString.string
	 enumerateFirstOccurrenceOfCharactersInString:searchString
										withBlock:^(NSRange range, BOOL *stop) {
											NSFont *boldFont = [RZFontManager() convertFont:channelNameFieldFont toHaveTrait:NSBoldFontMask];

											[resultString addAttribute:NSFontAttributeName value:boldFont range:range];
										} options:NSCaseInsensitiveSearch];

	NSString *networkName = searchResult.channel.associatedClient.networkNameAlt;

	[resultString appendString:TXTLS(@"TDCChannelSpotlightController[1007]", networkName)];

	return resultString;
}

- (NSColor *)channelNameTextColorSelected
{
	return [NSColor whiteColor];
}

- (NSColor *)channelNameTextColorDeselected
{
	return [NSColor labelColor];
}

- (NSString *)keyboardShortcut
{
	TDCChannelSpotlightSearchResult *searchResult = self.objectValue;

	if (searchResult == nil) {
		return @"";
	}

	TDCChannelSpotlightController *controller = searchResult.controller;

	NSArray *searchResults = controller.searchResultsFiltered;

	NSUInteger searchResultIndex = [searchResults indexOfObjectIdenticalTo:searchResult];

	if (searchResultIndex == controller.selectedSearchResult) {
		return @"↩︎";
	}

	if (searchResultIndex > 9) {
		return @"";
	}

	NSUInteger keyboardShortcutIndex = (searchResultIndex + 1);

	if (keyboardShortcutIndex == 10) {
		keyboardShortcutIndex = 0;
	}

	return [NSString stringWithFormat:@"⌘%lu", keyboardShortcutIndex];
}

- (NSColor *)keyboardShortcutTextColorSelected
{
	return [NSColor colorWithCalibratedWhite:0.9 alpha:1.0];
}

- (NSColor *)keyboardShortcutTextColorDeselected
{
	return [NSColor secondaryLabelColor];
}

- (NSString *)unreadCountDescription
{
	TDCChannelSpotlightSearchResult *searchResult = self.objectValue;

	if (searchResult == nil) {
		return @"";
	}

	NSUInteger nicknameHighlightCount = searchResult.channel.nicknameHighlightCount;

	NSString *nicknameHighlightCountDescription = nil;

	if (nicknameHighlightCount == 1) {
		nicknameHighlightCountDescription = TXTLS(@"TDCChannelSpotlightController[1004]",TXFormattedNumber(nicknameHighlightCount));
	} else {
		nicknameHighlightCountDescription = TXTLS(@"TDCChannelSpotlightController[1005]", TXFormattedNumber(nicknameHighlightCount));
	}

	NSUInteger unreadCount = searchResult.channel.treeUnreadCount;

	NSString *unreadCountDescription = nil;

	if (unreadCount == 1) {
		unreadCountDescription = TXTLS(@"TDCChannelSpotlightController[1002]", TXFormattedNumber(unreadCount));
	} else {
		unreadCountDescription = TXTLS(@"TDCChannelSpotlightController[1003]", TXFormattedNumber(unreadCount));
	}

	return TXTLS(@"TDCChannelSpotlightController[1006]", nicknameHighlightCountDescription, unreadCountDescription);
}

- (NSColor *)unreadCountDescriptionTextColorSelected
{
	return [NSColor colorWithCalibratedWhite:0.9 alpha:1.0];
}

- (NSColor *)unreadCountDescriptionTextColorDeselected
{
	return [NSColor secondaryLabelColor];
}

- (void)setObjectValue:(nullable id)objectValue
{
	super.objectValue = objectValue;

	[self reloadKeyValues];
}

- (void)reloadKeyValues
{
	[self willChangeValueForKey:@"channelName"];
	[self didChangeValueForKey:@"channelName"];

	[self willChangeValueForKey:@"keyboardShortcut"];
	[self didChangeValueForKey:@"keyboardShortcut"];

	[self willChangeValueForKey:@"unreadCountDescription"];
	[self didChangeValueForKey:@"unreadCountDescription"];
}

@end

#pragma mark -

@implementation TDCChannelSpotlightSearchResultRowView

- (BOOL)appearsVibrantDark
{
	TDCChannelSpotlightControllerPanel *panel = (TDCChannelSpotlightControllerPanel *)self.window;

	return panel.usingDarkAppearance;
}

- (NSTableViewSelectionHighlightStyle)selectionHighlightStyle
{
	if ([self appearsVibrantDark]) {
		return NSTableViewSelectionHighlightStyleRegular;
	} else {
		return NSTableViewSelectionHighlightStyleSourceList;
	}
}

- (void)setSelected:(BOOL)selected
{
	super.selected = selected;

	[self redrawSubviews];
}

- (void)redrawSubviews
{
	for (NSView *subview in self.subviews) {
		[subview setNeedsDisplay:YES];
	}
}

- (void)drawSelectionInRect:(NSRect)dirtyRect
{
	if ([self needsToDrawRect:dirtyRect] == NO) {
		return;
	}

	NSColor *selectionColor = nil;

	if ([self appearsVibrantDark]) {
		if (self.window.isActiveForDrawing) {
			selectionColor = [self selectionColorVibrantDarkActiveWindow];
		} else {
			selectionColor = [self selectionColorVibrantDarkInactiveWindow];
		}
	}

	if (selectionColor != nil) {
		[selectionColor set];

		NSRect selectionRect = self.bounds;

		NSRectFill(selectionRect);
	} else {
		[super drawSelectionInRect:dirtyRect];
	}
}

- (BOOL)isEmphasized
{
	return ([self appearsVibrantDark] == NO);
}

- (NSColor *)selectionColorVibrantDarkActiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
}

- (NSColor *)selectionColorVibrantDarkInactiveWindow
{
	return [NSColor colorWithCalibratedWhite:0.2 alpha:1.0];
}

@end

NS_ASSUME_NONNULL_END
