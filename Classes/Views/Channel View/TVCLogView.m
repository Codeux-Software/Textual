/* ********************************************************************* 
                  _____         _               _
                 |_   _|____  _| |_ _   _  __ _| |
                   | |/ _ \ \/ / __| | | |/ _` | |
                   | |  __/>  <| |_| |_| | (_| | |
                   |_|\___/_/\_\\__|\__,_|\__,_|_|

 Copyright (c) 2008 - 2010 Satoshi Nakagawa <psychs AT limechat DOT net>
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

#import "TVCLogObjectsPrivate.h"

@interface TVCLogView ()
@property (nonatomic, strong) id webViewBacking;
@end

@implementation TVCLogView

NSString * const TVCLogViewCommonUserAgentString = @"Textual/1.0 (+https://help.codeux.com/textual/Inline-Media-Scanner-User-Agent.kb)";

- (instancetype)initWithLogController:(TVCLogController *)logController
{
	if ((self = [super init])) {
		[self setLogController:logController];

		[self constructWebView];

		return self;
	}

	return nil;
}

+ (BOOL)isUsingWebKit2
{
	static BOOL _usesWebKit2 = NO;

	static BOOL _valueCached = NO;

	if (_valueCached == NO) {
		_valueCached = YES;

		BOOL usesWebKit2 = [RZUserDefaults() boolForKey:@"UsesWebKit2WhenAvailable"];

		if ( usesWebKit2) {
			_usesWebKit2 = [XRSystemInformation isUsingOSXElCapitanOrLater];
		}
	}

	return _usesWebKit2;
}

- (void)constructWebView
{
	if ([TVCLogView isUsingWebKit2]) {
		self.webViewBacking = [TVCLogViewInternalWK2 createNewInstanceWithHostView:self];
	} else {
		self.webViewBacking = [TVCLogViewInternalWK1 createNewInstanceWithHostView:self];
	}
}

- (NSString *)contentString
{
	NSString *contentString = [self returnStringByExecutingCommand:@"Textual.documentHTML"];

	return contentString;
}

- (BOOL)hasSelection
{
	NSString *selection = [self selection];

	return (NSObjectIsEmpty(selection) == NO);
}

- (NSString *)selection
{
	NSString *selection = [self returnStringByExecutingCommand:@"Textual.currentSelection"];

	return selection;
}

- (NSRect)selectionCoordinates
{
	id scriptResult = [self executeCommand:@"Textual.currentSelectionCoordinates"];

	id elementX = nil;
	id elementY = nil;
	id elementWidth = nil;
	id elementHeight = nil;

	if (scriptResult && [scriptResult isKindOfClass:[NSDictionary class]])
	{
		elementX = [scriptResult objectForKey:@"x"];
		elementY = [scriptResult objectForKey:@"y"];
		elementWidth = [scriptResult objectForKey:@"w"];
		elementHeight = [scriptResult objectForKey:@"h"];
	}
	else if (scriptResult && [scriptResult isKindOfClass:[WebScriptObject class]])
	{
		elementX = [scriptResult valueForKey:@"x"];
		elementY = [scriptResult valueForKey:@"y"];
		elementWidth = [scriptResult valueForKey:@"w"];
		elementHeight = [scriptResult valueForKey:@"h"];
	}
	else
	{
		return NSZeroRect;
	}

	if ([elementX isKindOfClass:[NSNumber class]] == NO ||
		[elementY isKindOfClass:[NSNumber class]] == NO ||
		[elementWidth isKindOfClass:[NSNumber class]] == NO ||
		[elementHeight isKindOfClass:[NSNumber class]] == NO)
	{
		return NSZeroRect;
	}

	return NSMakeRect(
		[elementX integerValue],
		[elementY integerValue],
		[elementWidth integerValue],
		[elementHeight integerValue]);
}

- (void)clearSelection
{
	[self executeStandaloneCommand:@"Textual.clearSelection"];
}

- (void)print
{
	// Printing is probably broken: <http://www.openradar.me/20217859>

	[[self webView] print:nil];
}

- (void)keyDown:(NSEvent *)e inView:(NSView *)view
{
	NSUInteger m = [e modifierFlags];

	BOOL cmd = (m & NSCommandKeyMask);
	BOOL alt = (m & NSAlternateKeyMask);
	BOOL ctrl = (m & NSControlKeyMask);

	if (ctrl == NO && alt == NO && cmd == NO) {
		[[self logController] logViewWebViewKeyDown:e];

		return;
	}

	[view keyDown:e];
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSURL *fileURL = [NSURL URLFromPasteboard:[sender draggingPasteboard]];

	if (fileURL) {
		NSString *filename = [fileURL relativePath];

		[[self logController] logViewWebViewRecievedDropWithFile:filename];
	}

	return NO;
}

- (void)informDelegateWebViewFinishedLoading
{
	[[self logController] logViewWebViewFinishedLoading];
}

- (void)informDelegateWebViewClosedUnexpectedly
{
	[[self logController] logViewWebViewClosedUnexpectedly];
}

- (TVCLogPolicy *)webViewPolicy
{
	return [[self webViewBacking] webViewPolicy];
}

@end

@implementation TVCLogView (TVCLogViewBackingProxy)

- (NSView *)webView
{
	return [self webViewBacking];
}

- (void)loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL
{
	if ([TVCLogView isUsingWebKit2]) {
		NSString *filename = [NSString stringWithFormat:@"%@.html", [NSString stringWithUUID]];

		NSURL *filePath = [baseURL URLByAppendingPathComponent:filename];

		NSError *fileWriteError = nil;

		if ([string writeToURL:filePath atomically:NO encoding:NSUTF8StringEncoding error:&fileWriteError] == NO) {
			LogToConsole(@"Failed to write temporary file: %@", [fileWriteError localizedDescription]);
		}

		WKWebView *webView = [self webViewBacking];

		[webView loadFileURL:filePath allowingReadAccessToURL:baseURL];
	} else {
		WebFrame *webViewFrame = [[self webViewBacking] mainFrame];

		[webViewFrame loadHTMLString:string baseURL:baseURL];
	}
}

- (void)stopLoading
{
	if ([TVCLogView isUsingWebKit2]) {
		WKWebView *webView = [self webViewBacking];

		[webView stopLoading];
	} else {
		WebFrame *webViewFrame = [[self webViewBacking] mainFrame];

		[webViewFrame stopLoading];
	}
}

- (void)findString:(NSString *)searchString movingForward:(BOOL)movingForward
{
	[[self webViewBacking] findString:searchString movingForward:movingForward];
}

@end

@implementation TVCLogView (TVCLogViewJavaScriptHandler)

- (void)executeJavaScript:(NSString *)code
{
	[[self webViewBacking] executeJavaScript:code];
}

- (id)executeJavaScriptWithResult:(NSString *)code
{
	return [[self webViewBacking] executeJavaScriptWithResult:code];
}

- (NSString *)escapeJavaScriptString:(NSString *)string
{
	NSString *escapedString = string;

	escapedString = [escapedString stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
	escapedString = [escapedString stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];

	return escapedString;
}

- (NSString *)compiledCommandCall:(NSString *)command withArguments:(NSArray *)arguments
{
	NSMutableString *compiledScript = [NSMutableString string];

	NSInteger argumentCount = 0;

	if ( arguments) {
		argumentCount = [arguments count];

		[arguments enumerateObjectsUsingBlock:^(id object, NSUInteger objectIndex, BOOL *stop)
		 {
			 if ([object isKindOfClass:[NSString class]])
			 {
				 NSString *objectEscaped = [self escapeJavaScriptString:object];

				 [compiledScript appendFormat:@"var _argument_%ld_ = \"%@\";\n", objectIndex, objectEscaped];
			 }
			 else if ([object isKindOfClass:[NSNumber class]])
			 {
				 if (strcmp([object objCType], @encode(BOOL)) == 0) {
					 if ([object boolValue] == YES) {
						 [compiledScript appendFormat:@"var _argument_%ld_ = true;\n", objectIndex];
					 } else {
						 [compiledScript appendFormat:@"var _argument_%ld_ = false;\n", objectIndex];
					 }
				 } else {
					 [compiledScript appendFormat:@"var _argument_%ld_ = %@;\n", objectIndex, object];
				 }
			 }
			 else if ([object isKindOfClass:[NSNull class]])
			 {
				 [compiledScript appendFormat:@"var _argument_%ld_ = null;\n", objectIndex];
			 }
			 else
			 {
				 [compiledScript appendFormat:@"var _argument_%ld_ = undefined;\n", objectIndex];
			 }
		 }];
	}

	[compiledScript appendFormat:@"%@(", command];

	for (NSInteger i = 0; i < argumentCount; i++) {
		if (i == (argumentCount - 1)) {
			[compiledScript appendFormat:@"_argument_%ld_", i];
		} else {
			[compiledScript appendFormat:@"_argument_%ld_, ", i];
		}
	}

	[compiledScript appendString:@");\n"];

	return [compiledScript copy];
}

- (void)executeStandaloneCommand:(NSString *)command
{
	[self executeStandaloneCommand:command withArguments:nil];
}

- (void)executeStandaloneCommand:(NSString *)command withArguments:(NSArray *)arguments
{
	NSString *compiledScript = [self compiledCommandCall:command withArguments:arguments];

	[self executeJavaScript:compiledScript];
}

- (id)executeCommand:(NSString *)command
{
	return [self executeCommand:command withArguments:nil];
}

- (id)executeCommand:(NSString *)command withArguments:(NSArray *)arguments
{
	NSString *compiledScript = [self compiledCommandCall:command withArguments:arguments];

	return [self executeJavaScriptWithResult:compiledScript];
}

- (BOOL)returnBooleanByExecutingCommand:(NSString *)command
{
	return [self returnBooleanByExecutingCommand:command withArguments:nil];
}

- (BOOL)returnBooleanByExecutingCommand:(NSString *)command withArguments:(NSArray *)arguments
{
	id scriptResult = [self executeCommand:command withArguments:arguments];

	if (scriptResult && [scriptResult isKindOfClass:[NSNumber class]] == NO) {
		return NO;
	}

	return [scriptResult boolValue];
}

- (NSString *)returnStringByExecutingCommand:(NSString *)command
{
	return [self returnStringByExecutingCommand:command withArguments:nil];
}

- (NSString *)returnStringByExecutingCommand:(NSString *)command withArguments:(NSArray *)arguments
{
	id scriptResult = [self executeCommand:command withArguments:arguments];

	if (scriptResult && [scriptResult isKindOfClass:[NSString class]] == NO) {
		return nil;
	}

	return scriptResult;
}

- (NSArray *)returnArrayByExecutingCommand:(NSString *)command
{
	return [self returnArrayByExecutingCommand:command withArguments:nil];
}

- (NSArray *)returnArrayByExecutingCommand:(NSString *)command withArguments:(NSArray *)arguments
{
	id scriptResult = [self executeCommand:command withArguments:arguments];

	if (scriptResult && [scriptResult isKindOfClass:[WebScriptObject class]] == NO) {
		return nil;
	}

	return [TVCLogScriptEventSink webScriptObjectToArray:scriptResult];
}

@end
