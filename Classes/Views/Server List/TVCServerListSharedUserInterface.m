/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
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

#import "NSColorHelper.h"
#import "NSObjectHelperPrivate.h"
#import "NSViewHelperPrivate.h"
#import "TPCPreferencesUserDefaults.h"
#import "TVCMainWindow.h"
#import "TVCServerListPrivate.h"
#import "TVCServerListSharedUserInterfacePrivate.h"

NS_ASSUME_NONNULL_BEGIN

@interface TVCServerListSharedUserInterface ()
@property (nonatomic, weak, readwrite) TVCServerList *serverList;
@property (nonatomic, assign, readwrite) BOOL isRetina;
@end

@interface TVCServerListMavericksUserInterfaceBackground ()
@property (nonatomic, weak) IBOutlet TVCServerList *serverList;
@end

@interface TVCServerListYosemiteUserInterface ()
@property (nonatomic, strong) TVCServerListYosemiteScaledUserInterface *constraints;
@end

@implementation TVCServerListSharedUserInterface

ClassWithDesignatedInitializerInitMethod

- (instancetype)initWithServerList:(TVCServerList *)serverList
{
	NSParameterAssert(serverList != nil);

	if ((self = [super init])) {
		self.serverList = serverList;

		self.isRetina = serverList.mainWindow.runningInHighResolutionMode;

		return self;
	}

	return nil;
}

- (void)setOutlineViewDefaultDisclosureTriangle:(NSImage *)image
{
	if (self.serverList.outlineViewDefaultDisclosureTriangle == nil) {
		self.serverList.outlineViewDefaultDisclosureTriangle = image;
	}
}

- (void)setOutlineViewAlternateDisclosureTriangle:(NSImage *)image
{
	if (self.serverList.outlineViewAlternateDisclosureTriangle == nil) {
		self.serverList.outlineViewAlternateDisclosureTriangle = image;
	}
}

- (NSImage *)disclosureTriangleInContext:(BOOL)up selected:(BOOL)selected
{
	if (up) {
		return self.serverList.outlineViewDefaultDisclosureTriangle;
	} else {
		return self.serverList.outlineViewAlternateDisclosureTriangle;
	}
}

- (nullable NSColor *)userConfiguredMessageCountHighlightedBadgeBackgroundColor
{
	return [RZUserDefaults() colorForKey:@"Server List Unread Message Count Badge Colors -> Highlight"];
}

@end

#pragma mark -

@implementation TVCServerListMavericksUserInterfaceBackground

- (void)drawRect:(NSRect)dirtyRect
{
	/* The following is specialized drawing for the normal source list
	 background when inside a backed layer view. */
	NSColor *backgroundColor = nil;

	if (self.mainWindow.isActiveForDrawing) {
		backgroundColor = [[self.serverList userInterfaceObjects] serverListBackgroundColorForActiveWindow];
	} else {
		backgroundColor = [[self.serverList userInterfaceObjects] serverListBackgroundColorForInactiveWindow];
	}

	if ( backgroundColor) {
		[backgroundColor set];

		NSRectFill(self.bounds);
	} else {
		NSGradient *backgroundGradient = [NSGradient sourceListBackgroundGradientColor];

		[backgroundGradient drawInRect:self.bounds angle:270.0];
	}
}

- (BOOL)isOpaque
{
	return YES;
}

@end

#pragma mark -

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wincomplete-implementation"
@implementation TVCServerListMavericksUserInterface
@end

@implementation TVCServerListYosemiteUserInterface

- (instancetype)initWithServerList:(TVCServerList *)serverList
{
	if ((self = [super initWithServerList:serverList])) {
		self.constraints =
		[[TVCServerListYosemiteScaledUserInterface alloc] initWithSharedInterface:self];

		return self;
	}

	return nil;
}

- (CGFloat)serverCellRowHeight
{
	return self.constraints.serverCellRowHeight;
}

- (CGFloat)channelCellRowHeight
{
	return self.constraints.channelCellRowHeight;
}

- (CGFloat)serverCellTextTopOffset
{
	return self.constraints.serverCellTextTopOffset;
}

- (CGFloat)channelCellTextTopOffset
{
	return self.constraints.channelCellTextTopOffset;
}

- (NSFont *)serverCellFont
{
	return self.constraints.serverCellFont;
}

- (NSFont *)channelCellFont
{
	return self.constraints.channelCellFont;
}

- (NSFont *)messageCountBadgeFont
{
	return self.constraints.messageCountBadgeFont;
}

- (CGFloat)messageCountBadgeHeight
{
	return self.constraints.messageCountBadgeHeight;
}

- (CGFloat)messageCountBadgeMinimumWidth
{
	return self.constraints.messageCountBadgeMinimumWidth;
}

- (CGFloat)messageCountBadgePadding
{
	return self.constraints.messageCountBadgePadding;
}

- (CGFloat)messageCountBadgeRightMargin
{
	return self.constraints.messageCountBadgeRightMargin;
}

- (CGFloat)messageCountBadgeTopOffset
{
	return self.constraints.messageCountBadgeTopOffset;
}

- (CGFloat)messageCountBadgeTextCenterYOffset
{
	return self.constraints.messageCountBadgeTextCenterYOffset;
}

@end
#pragma clang diagnostic pop

NS_ASSUME_NONNULL_END
