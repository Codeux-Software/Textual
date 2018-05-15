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

#import "TVCMainWindowTextViewYosemiteUserInterfacePrivate.h"

NS_ASSUME_NONNULL_BEGIN

@implementation TVCMainWindowTextViewYosemiteUserInterface

+ (NSColor *)blackInputTextFieldPlaceholderTextColor
{
	return [NSColor whiteColor];
}

+ (NSColor *)whiteInputTextFieldPlaceholderTextColor
{
	return [NSColor colorWithCalibratedWhite:0.15 alpha:1.0];
}

+ (NSColor *)blackInputTextFieldPrimaryTextColor
{
	return [NSColor colorWithCalibratedRed:0.660 green:0.660 blue:0.660 alpha:1.0];
}

+ (NSColor *)whiteInputTextFieldPrimaryTextColor
{
	return [NSColor grayColor];
}

+ (NSColor *)blackInputTextFieldInsideBlackBackgroundColor
{
	return [NSColor colorWithCalibratedRed:0.386 green:0.386 blue:0.386 alpha:1.0];
}

+ (NSColor *)blackInputTextFieldOutsideBottomGrayShadowColorWithRetina
{
	return [NSColor colorWithCalibratedWhite:0.0 alpha:0.15];
}

+ (NSColor *)blackInputTextFieldOutsideBottomGrayShadowColorWithoutRetina
{
	return [NSColor colorWithCalibratedWhite:0.0 alpha:0.10];
}

+ (NSColor *)whiteInputTextFieldOutsideTopsideWhiteBorder
{
	return [NSColor colorWithCalibratedWhite:1.0 alpha:1.0];
}

+ (NSColor *)whiteInputTextFieldInsideWhiteGradientStartColor
{
	return [NSColor colorWithCalibratedRed:0.992 green:0.992 blue:0.992 alpha:1.0];
}

+ (NSColor *)whiteInputTextFieldInsideWhiteGradientEndColor
{
	return [NSColor colorWithCalibratedRed:0.988 green:0.988 blue:0.988 alpha:1.0];
}

+ (NSGradient *)whiteInputTextFieldInsideWhiteGradient
{
	return [NSGradient gradientWithStartingColor:self.whiteInputTextFieldInsideWhiteGradientStartColor
									 endingColor:self.whiteInputTextFieldInsideWhiteGradientEndColor];
}

+ (NSColor *)whiteInputTextFieldOutsideBottomPrimaryGrayShadowColorWithRetina
{
	return [NSColor colorWithCalibratedWhite:0.0 alpha:0.15];
}

+ (NSColor *)whiteInputTextFieldOutsideBottomSecondaryGrayShadowColorWithRetina
{
	return [NSColor colorWithCalibratedWhite:0.0 alpha:0.06];
}

+ (NSColor *)whiteInputTextFieldOutsideBottomPrimaryGrayShadowColorWithoutRetina
{
	return [NSColor colorWithCalibratedWhite:0.0 alpha:0.10];
}

+ (NSColor *)writersProTextFieldCursorPinkColor
{
	return [NSColor colorWithCalibratedRed:0.850 green:0.0 blue:0.431 alpha:1.0];
}

+ (NSColor *)writersProTextFieldCursorBlueColor
{
	return [NSColor colorWithCalibratedRed:0.125 green:0.517 blue:0.760 alpha:1.0];
}

@end

NS_ASSUME_NONNULL_END
