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

#import "TextualApplication.h"

@interface TVCServerList : NSOutlineView
@property (nonatomic, weak) id keyDelegate;
@property (nonatomic, strong) id userInterfaceObjects;
@property (nonatomic, weak) IBOutlet TVCServerListMavericksUserInterfaceBackground *backgroundView;
@property (nonatomic, copy) NSImage *outlineViewDefaultDisclosureTriangle;
@property (nonatomic, copy) NSImage *outlineViewAlternateDisclosureTriangle;
@property (nonatomic, weak) IBOutlet NSVisualEffectView *visualEffectView;
@property (readonly) BOOL leftMouseIsDownInView;

/* addItemToList and removeItemFromList work two completely different ways.
 addItemToList expects that you have already added the item to the data source
 and that you are giving the list the index of the newly inserted item relative
 to the parent group. The list then manages that object. */
- (void)addItemToList:(NSInteger)index inParent:(id)parent;

/* removeItemFromList does not care about the index of an object as long as the
 object exists in the list. It will look for it anywhere. It checks if the item
 is a parent group or just a child and removes it based on that context. */
- (void)removeItemFromList:(id)oldObject;

/* Drawing. */
- (void)reloadAllDrawings;
- (void)reloadAllUnreadMessageCountBadges;

- (void)updateDrawingForItem:(IRCTreeItem *)cellItem;
- (void)updateDrawingForRow:(NSInteger)rowIndex;

- (void)updateMessageCountForItem:(IRCTreeItem *)cellItem;
- (void)updateMessageCountForRow:(NSInteger)rowIndex;

- (void)updateBackgroundColor; // Do not call.

- (void)windowDidChangeKeyState;
@end

@protocol TVCServerListDelegate <NSObject>
@required

- (void)serverListKeyDown:(NSEvent *)e;
@end
