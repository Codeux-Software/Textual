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

/* This file contains the base size of the server list 
 (TVCServerListYosemiteScaledUserInterface) and its three larger sizes.
 The three larger sizes are a subclass of TVCServerListYosemiteScaledUserInterface.
 Each subclass overrides ALL methods of its super. That way changing the
 alignment of super wont have any impact on other sizes. */

#import "NSObjectHelperPrivate.h"
#import "TVCServerListYosemiteUserInterfacePrivate.h"

NS_ASSUME_NONNULL_BEGIN

@interface TVCServerListYosemiteScaledUserInterface ()
@property (nonatomic, assign) BOOL isRetina;
@end

#pragma mark -
#pragma mark User Interface, Size 1

@implementation TVCServerListYosemiteScaledUserInterface

ClassWithDesignatedInitializerInitMethod

- (instancetype)initWithSharedInterface:(TVCServerListSharedUserInterface *)sharedInterface
{
	NSParameterAssert(sharedInterface != nil);

	if ((self = [super init])) {
		self.isRetina = sharedInterface.isRetina;

		return self;
	}

	return nil;
}

- (CGFloat)serverCellRowHeight
{
	return 22.0;
}

- (CGFloat)channelCellRowHeight
{
	return 20.0;
}

- (CGFloat)serverCellTextTopOffset
{
	return 3.0;
}

- (CGFloat)channelCellTextTopOffset
{
	if (self.isRetina) {
		return 2.5;
	} else {
		return 3.0;
	}
}

- (NSFont *)serverCellFont
{
	return [NSFont boldSystemFontOfSize:13.0];
}

- (NSFont *)channelCellFont
{
	return [NSFont systemFontOfSize:12.0];
}

- (NSFont *)messageCountBadgeFont
{
	return [NSFont cs_monospacedDigitSystemFontOfSize:11.0 traits:0];
}

- (CGFloat)messageCountBadgeHeight
{
	return 14.0;
}

- (CGFloat)messageCountBadgeMinimumWidth
{
	return 22.0;
}

- (CGFloat)messageCountBadgePadding
{
	return 6.0;
}

- (CGFloat)messageCountBadgeRightMargin
{
	return 3.0;
}

- (CGFloat)messageCountBadgeTopOffset
{
	return 1.0;
}

- (CGFloat)messageCountBadgeTextCenterYOffset
{
	return 0.0;
}

@end

#pragma mark -
#pragma mark User Interface, Size 2

@implementation TVCServerListYosemiteScaledUserInterfaceSize2

- (CGFloat)serverCellRowHeight
{
	return 25.0;
}

- (CGFloat)channelCellRowHeight
{
	return 22.0;
}

- (CGFloat)serverCellTextTopOffset
{
	return 3.0;
}

- (CGFloat)channelCellTextTopOffset
{
	if (self.isRetina) {
		return 2.5;
	} else {
		return 2.0;
	}
}

- (NSFont *)serverCellFont
{
	return [NSFont boldSystemFontOfSize:15.0];
}

- (NSFont *)channelCellFont
{
	return [NSFont systemFontOfSize:14.0];
}

- (NSFont *)messageCountBadgeFont
{
	CGFloat fontSize;

	if (self.isRetina) {
		fontSize = 13.5;
	} else {
		fontSize = 13.0;
	}

	return [NSFont cs_monospacedDigitSystemFontOfSize:fontSize traits:0];
}

- (CGFloat)messageCountBadgeHeight
{
	return 16.0;
}

- (CGFloat)messageCountBadgeMinimumWidth
{
	return 22.0;
}

- (CGFloat)messageCountBadgePadding
{
	return 7.0;
}

- (CGFloat)messageCountBadgeRightMargin
{
	return 3.0;
}

- (CGFloat)messageCountBadgeTopOffset
{
	return 1.0;
}

- (CGFloat)messageCountBadgeTextCenterYOffset
{
	if (self.isRetina) {
		return 0.5;
	} else {
		return 1.0;
	}
}

@end

#pragma mark -
#pragma mark User Interface, Size 3

@implementation TVCServerListYosemiteScaledUserInterfaceSize3

- (CGFloat)serverCellRowHeight
{
	return 28.0;
}

- (CGFloat)channelCellRowHeight
{
	return 26.0;
}

- (CGFloat)serverCellTextTopOffset
{
	return 3.0;
}

- (CGFloat)channelCellTextTopOffset
{
	if (self.isRetina) {
		return 2.5;
	} else {
		return 3.0;
	}
}

- (NSFont *)serverCellFont
{
	return [NSFont boldSystemFontOfSize:19.0];
}

- (NSFont *)channelCellFont
{
	return [NSFont systemFontOfSize:18.0];
}

- (NSFont *)messageCountBadgeFont
{
	CGFloat fontSize;

	if (self.isRetina) {
		fontSize = 16.5;
	} else {
		fontSize = 16.0;
	}

	return [NSFont cs_monospacedDigitSystemFontOfSize:fontSize traits:0];
}

- (CGFloat)messageCountBadgeHeight
{
	return 20.0;
}

- (CGFloat)messageCountBadgeMinimumWidth
{
	return 22.0;
}

- (CGFloat)messageCountBadgePadding
{
	return 8.0;
}

- (CGFloat)messageCountBadgeRightMargin
{
	return 3.0;
}

- (CGFloat)messageCountBadgeTopOffset
{
	return 1.0;
}

- (CGFloat)messageCountBadgeTextCenterYOffset
{
	return 0.0;
}

@end

#pragma mark -
#pragma mark User Interface, Size 4

@implementation TVCServerListYosemiteScaledUserInterfaceSize4

- (CGFloat)serverCellRowHeight
{
	return 31.0;
}

- (CGFloat)channelCellRowHeight
{
	return 30.0;
}

- (CGFloat)serverCellTextTopOffset
{
	return 3.0;
}

- (CGFloat)channelCellTextTopOffset
{
	if (self.isRetina) {
		return 2.5;
	} else {
		return 3.0;
	}
}

- (NSFont *)serverCellFont
{
	return [NSFont boldSystemFontOfSize:26.0];
}

- (NSFont *)channelCellFont
{
	return [NSFont systemFontOfSize:25.0];
}

- (NSFont *)messageCountBadgeFont
{
	return [NSFont cs_monospacedDigitSystemFontOfSize:22.0 traits:0];
}

- (CGFloat)messageCountBadgeHeight
{
	return 26.0;
}

- (CGFloat)messageCountBadgeMinimumWidth
{
	return 22.0;
}

- (CGFloat)messageCountBadgePadding
{
	return 9.0;
}

- (CGFloat)messageCountBadgeRightMargin
{
	return 3.0;
}

- (CGFloat)messageCountBadgeTopOffset
{
	return 1.0;
}

- (CGFloat)messageCountBadgeTextCenterYOffset
{
	if (self.isRetina) {
		return 0.5;
	} else {
		return 1.0;
	}
}

@end

NS_ASSUME_NONNULL_END
