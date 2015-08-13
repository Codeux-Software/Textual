/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

#import "TextualApplication.h"

#define _minimumSplitViewWidth			120

NSString * const _userDefaultsKey	  = @"NSSplitView Saved Frames -> TVCMainWindowSplitView";

@interface TVCMainWindowSplitView ()
@property (nonatomic, assign) BOOL restoredPositions;
@property (nonatomic, assign) BOOL stopFrameUpdatesForMemberList;
@property (nonatomic, assign) BOOL stopFrameUpdatesForServerList;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *serverListWidthConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *memberListWidthConstraint;
@end

@implementation TVCMainWindowSplitView

- (void)drawDividerInRect:(NSRect)rect
{
	NSColor *dividerColor = TVCMainWindowSplitViewDividerColor;

	if ([TPCPreferences invertSidebarColors]) {
		dividerColor = [dividerColor invertedColor];
	}

	[dividerColor set];

	NSRectFill(rect);
}

- (void)awakeFromNib
{
	[self setDelegate:self];
}

- (void)restorePositions
{
	if (self.restoredPositions == NO) {
		[self expandServerList];
		[self expandMemberList];
		
		self.restoredPositions = YES;
	}
}

- (NSRect)splitView:(NSSplitView *)splitView effectiveRect:(NSRect)proposedEffectiveRect forDrawnRect:(NSRect)drawnRect ofDividerAtIndex:(NSInteger)dividerIndex
{
	if (dividerIndex == 0) {
		if ([self isServerListCollapsed]) {
			return NSZeroRect;
		}
	} else {
		if ([self isMemberListCollapsed]) {
			return NSZeroRect;
		}
	}
	
	return proposedEffectiveRect;
}

- (BOOL)allowsVibrancy
{
	return YES;
}

- (void)expandServerList
{
	NSScrollView *scrollView = [mainWindowMemberList() enclosingScrollView];
	
	[scrollView setHasVerticalScroller:YES];
	
	NSView *subview = [self subviews][0];
	
	[subview setHidden:NO];
	
	[self setPosition:[self positionToRestoreServerListAt] ofDividerAtIndex:0];
	
	[self.serverListWidthConstraint setConstant:_minimumSplitViewWidth];

	self.stopFrameUpdatesForServerList = NO;
}

- (void)expandMemberList
{
	NSScrollView *scrollView = [mainWindowMemberList() enclosingScrollView];
	
	[scrollView setHasVerticalScroller:YES];
	
	NSView *subview = [self subviews][2];
	
	[subview setHidden:NO];
	
	[self setPosition:[self positionToRestoreMemberListAt] ofDividerAtIndex:1];
	
	[self.memberListWidthConstraint setConstant:_minimumSplitViewWidth];

	self.stopFrameUpdatesForMemberList = NO;
}

- (void)collapseServerList
{
	self.stopFrameUpdatesForServerList = YES;

	[self.serverListWidthConstraint setConstant:0.0];
	
	NSScrollView *scrollView = [mainWindowServerList() enclosingScrollView];
	
	[scrollView setHasVerticalScroller:NO];
	
	NSView *subview = [self subviews][0];
	
	[self setPosition:0.0 ofDividerAtIndex:0];
	
	[subview setHidden:YES];
}

- (void)collapseMemberList
{
	self.stopFrameUpdatesForMemberList = YES;
	
	[self.memberListWidthConstraint setConstant:0.0];
	
	NSView *subview = [self subviews][2];
	
	NSScrollView *scrollView = [mainWindowMemberList() enclosingScrollView];
	
	[scrollView setHasVerticalScroller:NO];
	
	NSRect windowFrame = [mainWindow() frame];
	
	[self setPosition:NSWidth(windowFrame) ofDividerAtIndex:1];
	
	[subview setHidden:YES];
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

- (NSInteger)positionForDividerAtIndex:(NSInteger)idx
{
	NSRect subviewFrame = [[self subviews][idx] frame];
	
	return (NSMaxX(subviewFrame) + ([self dividerThickness] * idx));
}

- (NSInteger)positionToRestoreServerListAt
{
	NSDictionary *frames = [self savedFrames];
	
	NSInteger position = 0;
	
	if ([frames containsKey:@"serverList"]) {
		position = [frames integerForKey:@"serverList"];
	}
	
	if (position < TVCMainWindowSplitViewMinimumDividerPosition) {
		position = TVCMainWindowSplitViewServerListDefaultPosition;
	} else if (position > TVCMainWindowSplitViewMaximumDividerPosition) {
		position = TVCMainWindowSplitViewServerListDefaultPosition;
	}
	
	return position;
}

- (NSInteger)positionToRestoreMemberListAt
{
	return [self positionToRestoreMemberListAt:YES];
}

- (NSInteger)positionToRestoreMemberListAt:(BOOL)correctedFrame
{
	NSDictionary *frames = [self savedFrames];
	
	NSInteger position = 0;
	
	if ([frames containsKey:@"memberList"]) {
		position = [frames integerForKey:@"memberList"];
	}
	
	if (position < TVCMainWindowSplitViewMinimumDividerPosition) {
		position = TVCMainWindowSplitViewMemberListDefaultPosition;
	} else if (position > TVCMainWindowSplitViewMaximumDividerPosition) {
		position = TVCMainWindowSplitViewMemberListDefaultPosition;
	}
	
	if (correctedFrame) {
		NSRect windowFrame = [mainWindow() frame];
		
		return ((NSWidth(windowFrame) - position) - [self dividerThickness]);
	}
	
	return position;
}

- (NSInteger)positionOfServerListForSaving
{
	NSInteger position = [self positionForDividerAtIndex:0];
	
	if (position < TVCMainWindowSplitViewMinimumDividerPosition) {
		position = TVCMainWindowSplitViewServerListDefaultPosition;
	} else if (position > TVCMainWindowSplitViewMaximumDividerPosition) {
		position = TVCMainWindowSplitViewServerListDefaultPosition;
	}
	
	return position;
}

- (NSInteger)positionOfMemberListForSaving
{
	NSInteger rawPosition = [self positionForDividerAtIndex:1];
	
	NSRect windowFrame = [mainWindow() frame];
	
	NSInteger position = ((rawPosition - NSWidth(windowFrame)) * (-1));
	
	if (position < TVCMainWindowSplitViewMinimumDividerPosition) {
		position = TVCMainWindowSplitViewMemberListDefaultPosition;
	} else if (position > TVCMainWindowSplitViewMaximumDividerPosition) {
		position = TVCMainWindowSplitViewMemberListDefaultPosition;
	}
	
	return position;
}

- (void)updateSavedFrames
{
	NSInteger serverListPosition = 0;
	NSInteger memberListPosition = 0;
	
	if (self.stopFrameUpdatesForServerList) {
		serverListPosition = [self positionToRestoreServerListAt];
	} else {
		serverListPosition = [self positionOfServerListForSaving];
	}
	
	if (self.stopFrameUpdatesForMemberList) {
		memberListPosition = [self positionToRestoreMemberListAt:NO];
	} else {
		memberListPosition = [self positionOfMemberListForSaving];
	}
	
	NSDictionary *newFrames = @{
		@"serverList" : @(serverListPosition),
		@"memberList" : @(memberListPosition),
	};
	
	[RZUserDefaults() setObject:newFrames forKey:_userDefaultsKey];
}

- (NSDictionary *)savedFrames
{
	return [RZUserDefaults() objectForKey:_userDefaultsKey];
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldSize
{
	if (self.restoredPositions) {
		[self updateSavedFrames];
	}
	
	[super resizeWithOldSuperviewSize:oldSize];
}

- (BOOL)isServerListCollapsed
{
	return [self isSubviewCollapsed:[self subviews][0]];
}

- (BOOL)isMemberListCollapsed
{
	return [self isSubviewCollapsed:[self subviews][2]];
}

@end
