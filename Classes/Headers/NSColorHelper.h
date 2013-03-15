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

#define TXCalibratedRGBColor(r, g, b)		([NSColor internalCalibratedRed:r green:g blue:b alpha:1.0])

@interface NSColor (TXColorHelper)
+ (id)defineUserInterfaceItem:(id)normalItem invertedItem:(id)invertedItem;
+ (id)defineUserInterfaceItem:(id)normalItem invertedItem:(id)invertedItem withOperator:(BOOL)specialCondition;

- (NSColor *)invertColor;

+ (NSColor *)formatterWhiteColor;
+ (NSColor *)formatterBlackColor;
+ (NSColor *)formatterNavyBlueColor;
+ (NSColor *)formatterDarkGreenColor;
+ (NSColor *)formatterRedColor;
+ (NSColor *)formatterBrownColor;
+ (NSColor *)formatterPurpleColor;
+ (NSColor *)formatterOrangeColor;
+ (NSColor *)formatterYellowColor;
+ (NSColor *)formatterLimeGreenColor;
+ (NSColor *)formatterTealColor;
+ (NSColor *)formatterAquaCyanColor;
+ (NSColor *)formatterLightBlueColor;
+ (NSColor *)formatterFuchsiaPinkColor;
+ (NSColor *)formatterNormalGrayColor;
+ (NSColor *)formatterLightGrayColor;

+ (NSArray *)possibleFormatterColors;

+ (NSColor *)fromCSS:(NSString *)str;

+ (NSColor *)sourceListBackgroundColor;
+ (NSColor *)sourceListBackgroundColorTop;
+ (NSColor *)outlineViewHeaderTextColor;
+ (NSColor *)outlineViewHeaderDisabledTextColor;

+ (NSColor *)internalCalibratedRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
@end

/* Gradients are color related so just slap this in here… */
@interface NSGradient (TXGradientHelper)
+ (NSGradient *)sourceListBackgroundGradientColor;

+ (NSGradient *)gradientWithStartingColor:(NSColor *)startingColor endingColor:(NSColor *)endingColor;
@end
