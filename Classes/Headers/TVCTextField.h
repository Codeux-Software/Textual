/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

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

#define TXDefaultTextFieldFontColor         [NSColor colorWithCalibratedWhite:0.15 alpha:1.0]
#define TXDefaultTextFieldFont              [NSFont fontWithName:@"Helvetica" size:12.0]

@interface TVCTextField : NSTextView 
@property (nonatomic, strong) TLOKeyEventHandler *keyHandler;
@property (nonatomic, assign) dispatch_queue_t formattingQueue;

- (BOOL)isAtTopOfView;
- (BOOL)isAtBottomOfView;

- (NSInteger)selectedLineNumber;
- (NSInteger)numberOfLines;

- (void)keyDownToSuper:(NSEvent *)e;

- (void)setKeyHandlerTarget:(id)target;

- (void)registerKeyHandler:(SEL)selector key:(NSInteger)code modifiers:(NSUInteger)mods;
- (void)registerKeyHandler:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods;

- (NSAttributedString *)attributedStringValue;
- (void)setAttributedStringValue:(NSAttributedString *)string;

- (NSString *)stringValue;
- (void)setStringValue:(NSString *)string;

- (void)sanitizeTextField:(BOOL)paste;

- (void)removeAttribute:(id)attr inRange:(NSRange)local;
- (void)setAttributes:(id)attrs inRange:(NSRange)local;

- (void)addUndoActionForAttributes:(NSDictionary *)attributes inRange:(NSRange)local;
@end
