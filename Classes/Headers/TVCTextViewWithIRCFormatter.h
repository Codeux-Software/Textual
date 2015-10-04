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

@interface TVCTextViewWithIRCFormatter : NSTextView <NSTextViewDelegate>
@property (nonatomic, copy) NSFont *preferredFont;
@property (nonatomic, copy) NSColor *preferredFontColor;
@property (nonatomic, strong) TLOKeyEventHandler *keyEventHandler;

@property (getter=isAtTopOfView, readonly) BOOL atTopOfView;
@property (getter=isAtBottomOfView, readonly) BOOL atBottomOfView;

@property (readonly) NSInteger selectedLineNumber;
@property (readonly) NSInteger numberOfLines;

- (NSInteger)highestHeightBelowHeight:(NSInteger)maximumHeight withPadding:(NSInteger)valuePadding;

- (void)keyDownToSuper:(NSEvent *)e;

- (void)setKeyHandlerTarget:(id)target;

- (void)registerKeyHandler:(SEL)selector key:(NSInteger)code modifiers:(NSUInteger)mods;
- (void)registerKeyHandler:(SEL)selector character:(UniChar)c modifiers:(NSUInteger)mods;

@property (copy) NSAttributedString *attributedStringValue;

@property (copy) NSString *stringValue;

- (void)resetTextColorInRange:(NSRange)range;
- (void)resetTypeSetterAttributes;

- (void)updateAllFontSizesToMatchTheDefaultFont;

- (void)textDidChange:(NSNotification *)aNotification;

- (NSString *)stringValueWithIRCFormatting;
- (void)setAttributedStringValueWithStringContainingIRCFormatting:(NSString *)stringValue;
@end
