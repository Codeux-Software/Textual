/* ********************************************************************* 
				  _____         _               _
				 |_   _|____  _| |_ _   _  __ _| |
				   | |/ _ \ \/ / __| | | |/ _` | |
				   | |  __/>  <| |_| |_| | (_| | |
				   |_|\___/_/\_\\__|\__,_|\__,_|_|

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

@interface IRCTreeItem : NSObject <NSTableViewDataSource, NSTableViewDelegate>
@property (readonly) NSString *label;
@property (readonly) NSString *name;
@property (nonatomic, copy) NSString *treeUUID; // Unique Identifier (UUID)
@property (readonly) BOOL isActive;
@property (readonly) BOOL isUnread;
@property (readonly) BOOL isClient;
@property (readonly) BOOL isChannel;
@property (readonly) BOOL isPrivateMessage;
@property (nonatomic, strong) IRCClient *associatedClient;
@property (nonatomic, strong) IRCChannel *associatedChannel;
@property (nonatomic, assign) NSInteger dockUnreadCount;
@property (nonatomic, assign) NSInteger treeUnreadCount;
@property (nonatomic, assign) NSInteger nicknameHighlightCount;
@property (nonatomic, strong) TVCLogController *viewController;
@property (nonatomic, strong) TVCLogControllerOperationQueue *printingQueue;

- (void)resetState;

@property (readonly) NSInteger numberOfChildren;
- (IRCTreeItem *)childAtIndex:(NSInteger)index;
@end
