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

#import "NSObjectHelperPrivate.h"
#import "TVCMemberListYosemiteUserInterfacePrivate.h"

NS_ASSUME_NONNULL_BEGIN

@interface TVCMemberListYosemiteScaledUserInterface ()
@property (nonatomic, assign) BOOL isRetina;
@end

#pragma mark -
#pragma mark User Interface, Size 1

@implementation TVCMemberListYosemiteScaledUserInterface

ClassWithDesignatedInitializerInitMethod

- (instancetype)initWithSharedInterface:(TVCMemberListSharedUserInterface *)sharedInterface
{
	NSParameterAssert(sharedInterface != nil);

	if ((self = [super init])) {
		self.isRetina = sharedInterface.isRetina;

		return self;
	}

	return nil;
}

- (CGFloat)cellRowHeight
{
	return 20.0;
}

- (NSFont *)cellTextFont
{
	return [NSFont systemFontOfSize:12.0];
}

- (CGFloat)cellTextTopOffset
{
	if (self.isRetina) {
		return 2.5;
	} else {
		return 3.0;
	}
}

- (NSFont *)userMarkBadgeFont
{
	return [RZFontManager() fontWithFamily:@"Helvetica" traits:0 weight:15 size:12.0];
}

- (NSFont *)userMarkBadgeFontSelected
{
	return [RZFontManager() fontWithFamily:@"Helvetica" traits:0 weight:15 size:12.0];
}

- (CGFloat)userMarkBadgeWidth
{
	return 16.0;
}

- (CGFloat)userMarkBadgeHeight
{
	return 16.0;
}

- (CGFloat)userMarkBadgeTopOffset
{
	return 1.0;
}

@end

#pragma mark -
#pragma mark User Interface, Size 2

@implementation TVCMemberListYosemiteScaledUserInterfaceSize2

- (CGFloat)cellRowHeight
{
	return 22.0;
}

- (NSFont *)cellTextFont
{
	return [NSFont systemFontOfSize:14.0];
}

- (CGFloat)cellTextTopOffset
{
	if (self.isRetina) {
		return 2.5;
	} else {
		return 3.0;
	}
}

- (NSFont *)userMarkBadgeFont
{
	return [RZFontManager() fontWithFamily:@"Helvetica" traits:0 weight:15 size:12.0];
}

- (NSFont *)userMarkBadgeFontSelected
{
	return [RZFontManager() fontWithFamily:@"Helvetica" traits:0 weight:15 size:12.0];
}

- (CGFloat)userMarkBadgeWidth
{
	return 18.0;
}

- (CGFloat)userMarkBadgeHeight
{
	return 18.0;
}

- (CGFloat)userMarkBadgeTopOffset
{
	return 1.0;
}

@end

#pragma mark -
#pragma mark User Interface, Size 3

@implementation TVCMemberListYosemiteScaledUserInterfaceSize3

- (CGFloat)cellRowHeight
{
	return 26.0;
}

- (NSFont *)cellTextFont
{
	return [NSFont systemFontOfSize:18.0];
}

- (CGFloat)cellTextTopOffset
{
	if (self.isRetina) {
		return 2.5;
	} else {
		return 3.0;
	}
}

- (NSFont *)userMarkBadgeFont
{
	return [RZFontManager() fontWithFamily:@"Helvetica" traits:0 weight:15 size:12.0];
}

- (NSFont *)userMarkBadgeFontSelected
{
	return [RZFontManager() fontWithFamily:@"Helvetica" traits:0 weight:15 size:12.0];
}

- (CGFloat)userMarkBadgeWidth
{
	return 22.0;
}

- (CGFloat)userMarkBadgeHeight
{
	return 22.0;
}

- (CGFloat)userMarkBadgeTopOffset
{
	return 1.0;
}

@end

#pragma mark -
#pragma mark User Interface, Size 4

@implementation TVCMemberListYosemiteScaledUserInterfaceSize4

- (CGFloat)cellRowHeight
{
	return 30.0;
}

- (NSFont *)cellTextFont
{
	return [NSFont systemFontOfSize:25.0];
}

- (CGFloat)cellTextTopOffset
{
	if (self.isRetina) {
		return 2.5;
	} else {
		return 3.0;
	}
}

- (NSFont *)userMarkBadgeFont
{
	return [NSFont systemFontOfSize:22.5];
}

- (NSFont *)userMarkBadgeFontSelected
{
	return [NSFont systemFontOfSize:22.0];
}

- (CGFloat)userMarkBadgeWidth
{
	return 26.0;
}

- (CGFloat)userMarkBadgeHeight
{
	return 26.0;
}

- (CGFloat)userMarkBadgeTopOffset
{
	return 1.0;
}

@end

NS_ASSUME_NONNULL_END
