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

@interface TXWindowController ()
@property (nonatomic, strong) NSMutableDictionary *windowObjects;
@end

@implementation TXWindowController

- (instancetype)init
{
	if ((self = [super init])) {
		self.windowObjects = [NSMutableDictionary dictionary];

		return self;
	}

	return nil;
}

- (void)prepareForApplicationTermination
{
	@synchronized(self.windowObjects) {
		[self.windowObjects removeAllObjects];
		 self.windowObjects = nil;
	}
}

+ (NSString *)windowDescriptionForWindow:(id)window
{
	return [self windowDescriptionForWindow:window inRelationTo:nil];
}

+ (NSString *)windowDescriptionForWindow:(id)window inRelationTo:(id)relatedObject
{
	if (window) {
		NSString *windowClass = NSStringFromClass([window class]);

		if (relatedObject) {
			return [NSString stringWithFormat:@"%@ -> %@", [relatedObject description], windowClass];
		} else {
			return windowClass;
		}
	}

	return nil;
}

- (void)addWindowToWindowList:(id)window
{
	[self addWindowToWindowList:window inRelationTo:nil];
}

- (void)addWindowToWindowList:(id)window inRelationTo:(id)relatedObject
{
	NSString *windowDescription = [TXWindowController windowDescriptionForWindow:window inRelationTo:relatedObject];

	if (windowDescription == nil) {
		return; // Cannot continue...
	}

	[self addWindowToWindowList:window withDescription:windowDescription];
}

- (void)addWindowToWindowList:(id)window withDescription:(NSString *)windowDescription
{
	if (windowDescription == nil || [windowDescription length] <= 0) {
		return; // Cannot continue...
	}

	if (window == nil || [window respondsToSelector:@selector(window)] == NO) {
		return; // Refuse to add "window"
	}

	@synchronized(self.windowObjects) {
		self.windowObjects[windowDescription] = window;
	}
}

- (void)removeWindowFromWindowList:(id)window
{
	[self removeWindowFromWindowList:window inRelationTo:nil];
}

- (void)removeWindowFromWindowList:(id)window inRelationTo:(id)relatedObject
{
	if (window && [window isKindOfClass:[NSArray class]]) {
		for (id object in window) {
			[self removeWindowFromWindowList:object inRelationTo:relatedObject];
		}

		return; // Do not continue...
	}

	BOOL windowWasString = NO;

	NSString *windowDescription = nil;

	if ([window isKindOfClass:[NSString class]]) {
		windowWasString = YES;

		windowDescription = window;
	} else {
		windowDescription = [TXWindowController windowDescriptionForWindow:window inRelationTo:relatedObject];
	}

	if (windowDescription == nil) {
		return; // Cannot continue...
	}

	@synchronized(self.windowObjects) {
		/* If the description does not exist, we scan our window list 
		 for the exact object. */
		if (self.windowObjects[windowDescription] == nil && windowWasString == NO) {
			NSString *windowToRemove = nil;

			for (NSString *windowDescription in self.windowObjects) {
				id windowObject = self.windowObjects[windowDescription];

				if ([windowObject isEqual:window]) {
					windowToRemove = windowDescription;

					break;
				}
			}

			if (windowToRemove) {
				[self.windowObjects removeObjectForKey:windowToRemove];
			}
		} else {
			[self.windowObjects removeObjectForKey:windowDescription];
		}
	}
}

- (id)windowFromWindowList:(NSString *)windowDescription
{
	if (windowDescription == nil) {
		return nil;
	}

	@synchronized(self.windowObjects) {
		return self.windowObjects[windowDescription];
	}
}

- (NSArray *)windowsFromWindowList:(NSArray *)windowDescriptions
{
	if (windowDescriptions == nil) {
		return nil;
	}

	@synchronized(self.windowObjects) {
		NSMutableArray *returnedValues = [NSMutableArray array];

		for (id windowDescription in windowDescriptions) {
			if ([windowDescription isKindOfClass:[NSString class]] == NO) {
				continue;
			}

			id windowObject = self.windowObjects[windowDescription];

			if (windowObject) {
				[returnedValues addObject:windowObject];
			}
		}

		return [returnedValues copy];
	}

	return nil;
}

- (BOOL)maybeBringWindowForward:(NSString *)windowDescription
{
	id windowObject = [self windowFromWindowList:windowDescription];

	if (windowObject) {
		NSWindow *window = [windowObject window];

		[window makeKeyAndOrderFront:nil];

		return YES;
	}

	return NO;
}

- (void)popMainWindowSheetIfExists
{
	/* Close any existing sheet by canceling the previous instance of it. */
	NSWindow *attachedSheet = [mainWindow() attachedSheet];

	if (attachedSheet) {
		@synchronized(self.windowObjects) {
			for (NSString *windowDescription in self.windowObjects) {
				id windowObject = self.windowObjects[windowDescription];

				if ([[windowObject class] isSubclassOfClass:[TDCSheetBase class]]) {
					NSWindow *ownedWindow = (id)[windowObject sheet];

					if ([ownedWindow isEqual:attachedSheet]) {
						[windowObject cancel:nil];

						return; // No need to continue.
					}
				}
			}
		}
	}

	[attachedSheet close];
}

@end
