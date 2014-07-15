/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

#define _minimumSplitViewWidth			120

@interface TVCMainWindowSplitView ()
@property (nonatomic, nweak) IBOutlet NSLayoutConstraint *serverListWidthConstraint;
@property (nonatomic, nweak) IBOutlet NSLayoutConstraint *memberListWidthConstraint;
@end

@implementation TVCMainWindowSplitView

- (void)drawDividerInRect:(NSRect)rect
{
	NSColor *dividerColor = TVCMainWindowSplitViewDividerColor;

	if ([TPCPreferences invertSidebarColors]) {
		dividerColor = [dividerColor invertColor];
	}

	[dividerColor set];

	NSRectFill(rect);
}

- (void)awakeFromNib
{
	[self setDelegate:self];
}

- (BOOL)splitView:(NSSplitView *)splitView shouldHideDividerAtIndex:(NSInteger)dividerIndex
{
	if (dividerIndex == 0) {
		return [self isServerListCollapsed];
	} else {
		return [self isMemberListCollapsed];
	}
}

- (BOOL)allowsVibrancy
{
	return YES;
}

- (void)expandServerList
{
	[self.serverListWidthConstraint setConstant:_minimumSplitViewWidth];
	
	[self expandViewAtIndex:0];
}

- (void)expandMemberList
{
	[self.memberListWidthConstraint setConstant:_minimumSplitViewWidth];
	
	[self expandViewAtIndex:2];
}

- (void)collapseServerList
{
	[self.serverListWidthConstraint setConstant:0.0];
	
	[self collapseViewAtIndex:0];
}

- (void)collapseMemberList
{
	[self.memberListWidthConstraint setConstant:0.0];

	[self collapseViewAtIndex:2];
}

- (void)toggleServerListVisbility
{
	if ([self isServerListCollapsed]) {
		[self expandServerList];
	} else {
		[self collapseServerList];
	}
}

- (void)toggleMemberListVisbility
{
	if ([self isMemberListCollapsed]) {
		[self expandMemberList];
	} else {
		[self collapseMemberList];
	}
}

- (BOOL)isServerListCollapsed
{
	return [self isSubviewCollapsed:[self subviews][0]];
}

- (BOOL)isMemberListCollapsed
{
	return [self isSubviewCollapsed:[self subviews][2]];
}

- (void)collapseViewAtIndex:(NSInteger)dividerIndex
{
	NSView *theView = [self subviews][dividerIndex];
	
	[theView setHidden:YES];
	
	[self adjustSubviews];
}

- (void)expandViewAtIndex:(NSInteger)dividerIndex
{
	NSView *theView = [self subviews][dividerIndex];
	
	[theView setHidden:NO];
	
	[self adjustSubviews];
}

@end
