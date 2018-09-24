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

#import "TXMasterController.h"
#import "IRCClient.h"
#import "IRCChannelPrivate.h"
#import "IRCWorldPrivate.h"
#import "TVCServerList.h"
#import "TVCMemberList.h"
#import "TDCBuddyListDialogInternal.h"
#import "TDCBuddyListDialogDropViewPrivate.h"

NS_ASSUME_NONNULL_BEGIN

@interface TDCBuddyListDialogDropView ()
@property (nonatomic, weak) IBOutlet TDCBuddyListDialog *parentDialog;
@property (nonatomic, weak) IBOutlet NSView *visualDropView;
@property (nonatomic, strong, nullable) IRCClient *lastDraggedClient;
@property (nonatomic, copy, nullable) NSArray<NSString *> *lastDraggedNicknames;
@end

@implementation TDCBuddyListDialogDropView

- (void)hideVisualDropView
{
	self.visualDropView.hidden = YES;
}

- (void)showVisualDropView
{
	self.visualDropView.hidden = NO;
}

- (void)awakeFromNib
{
	[self registerForDraggedTypes:@[TVCServerListDragType, TVCMemberListDragType]];
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pasteboard = [sender draggingPasteboard];

	NSString *pasteboardType = [pasteboard availableTypeFromArray:[self registeredDraggedTypes]];

	if ([pasteboardType isEqualToString:TVCServerListDragType])
	{
		NSString *draggedItemToken = [pasteboard stringForType:TVCServerListDragType];

		IRCTreeItem *draggedItem = [worldController() findItemWithPasteboardString:draggedItemToken];

		if (draggedItem.isPrivateMessage == NO) {
			return NSDragOperationNone;
		}

		self.lastDraggedClient = draggedItem.associatedClient;

		self.lastDraggedNicknames = @[draggedItem.name];
	}
	else if ([pasteboardType isEqualToString:TVCMemberListDragType])
	{
		NSData *draggedData = [pasteboard dataForType:TVCMemberListDragType];

		BOOL draggedDataProcessed =
		[IRCChannel readNicknamesFromPasteboardData:draggedData withBlock:^(IRCChannel *channel, NSArray<NSString *> *nicknames) {
			self.lastDraggedClient = channel.associatedClient;

			self.lastDraggedNicknames = nicknames;
		}];

		if (draggedDataProcessed == NO) {
			return NSDragOperationNone;
		}
	}

	return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	[self.parentDialog droppedNicknames:self.lastDraggedNicknames
							 fromClient:self.lastDraggedClient];

	self.lastDraggedClient = nil;

	self.lastDraggedNicknames = nil;

	return YES;
}

- (BOOL)wantsPeriodicDraggingUpdates
{
	return NO;
}

@end

NS_ASSUME_NONNULL_END
