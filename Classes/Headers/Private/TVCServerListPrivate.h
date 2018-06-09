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

#import "TVCServerList.h"

NS_ASSUME_NONNULL_BEGIN

@class TVCServerListAppearance;
@class TVCServerListMavericksBackgroundBox;

@interface TVCServerList ()
@property (nonatomic, weak) id keyDelegate;
@property (nonatomic, copy, nullable) NSImage *outlineViewDefaultDisclosureTriangle;
@property (nonatomic, copy, nullable) NSImage *outlineViewAlternateDisclosureTriangle;

- (TVCServerListAppearance *)userInterfaceObjects;
- (nullable NSVisualEffectView *)visualEffectView;
- (nullable TVCServerListMavericksBackgroundBox *)backgroundView;

- (BOOL)leftMouseIsDownInView;

- (void)addItemToList:(NSUInteger)rowIndex inParent:(nullable id)parent;

- (void)removeItemFromList:(id)object;

- (void)reloadAllDrawings;
- (void)reloadAllUnreadMessageCountBadges;

- (void)updateMessageCountForItem:(IRCTreeItem *)cellItem;
- (void)updateMessageCountForRow:(NSInteger)rowIndex;

- (void)updateBackgroundColor;

- (void)windowDidChangeKeyState;
@end

@protocol TVCServerListDelegate <NSObject>
@required

- (void)serverListKeyDown:(NSEvent *)e;
@end

NS_ASSUME_NONNULL_END
