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

#import "WebScriptObjectHelper.h"

@interface TVCLogView ()
@property (nonatomic, strong) id webViewBacking;
@property (nonatomic, readwrite, assign) BOOL isUsingWebKit2;
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

- (void)dealloc
{
	self.webViewBacking = nil;
}

- (void)constructWebView
{
	BOOL isUsingWebKit2 = [TPCPreferences webKit2Enabled];

	[self setIsUsingWebKit2:isUsingWebKit2];

	if (isUsingWebKit2) {
		self.webViewBacking = [[TVCLogViewInternalWK2 alloc] initWithHostView:self];
	} else {
		self.webViewBacking = [[TVCLogViewInternalWK1 alloc] initWithHostView:self];
	}
}

- (void)copyContentString
{
	[self stringByEvaluatingFunction:@"Textual.documentHTML" completionHandler:^(NSString *result) {
		[RZPasteboard() setStringContent:result];
	}];
}

- (BOOL)hasSelection
{
	NSString *selection = [self selection];

	return (NSObjectIsEmpty(selection) == NO);
}

- (void)clearSelection
{
	[self evaluateFunction:@"Textual.clearSelection"];
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
	[[self webViewBacking] emptyCaches:^{
		[self _loadHTMLString:string baseURL:baseURL];
	}];
}

- (void)_loadHTMLString:(NSString *)string baseURL:(NSURL *)baseURL
{
	if ([self isUsingWebKit2])
	{
		WKWebView *webView = [self webViewBacking];

		if ([themeController() usesTemporaryPath]) {
			NSString *filename = [NSString stringWithFormat:@"%@.html", [NSString stringWithUUID]];

			NSURL *filePath = [baseURL URLByAppendingPathComponent:filename];

			NSError *fileWriteError = nil;

			if ([string writeToURL:filePath atomically:NO encoding:NSUTF8StringEncoding error:&fileWriteError] == NO) {
				LogToConsole(@"Failed to write temporary file: %@", [fileWriteError localizedDescription]);
			}

			[webView loadFileURL:filePath allowingReadAccessToURL:baseURL];
		} else {
			[webView loadHTMLString:string baseURL:baseURL];
		}
	}
	else
	{
		WebFrame *webViewFrame = [[self webViewBacking] mainFrame];

		[webViewFrame loadHTMLString:string baseURL:baseURL];
	}
}

- (void)stopLoading
{
	if ([self isUsingWebKit2]) {
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

- (void)evaluateJavaScript:(NSString *)code
{
	[[self webViewBacking] _t_evaluateJavaScript:code completionHandler:nil];
}

- (void)evaluateJavaScript:(NSString *)code completionHandler:(void (^)(id))completionHandler
{
	[[self webViewBacking] _t_evaluateJavaScript:code completionHandler:completionHandler];
}

+ (NSString *)descriptionOfJavaScriptResult:(id)scriptResult
{
	if ([scriptResult isKindOfClass:[NSString class]])
	{
		return scriptResult;
	}
	else if ([scriptResult isKindOfClass:[NSArray class]] ||
			 [scriptResult isKindOfClass:[NSDictionary class]])
	{
		return [scriptResult description];
	}
	else if ([scriptResult isKindOfClass:[NSNumber class]])
	{
		if (strcmp([scriptResult objCType], @encode(BOOL)) == 0) {
			if ([scriptResult boolValue] == YES) {
				return @"true";
			} else {
				return @"false";
			}
		} else {
			return [scriptResult stringValue];
		}
	}
	else if ([scriptResult isKindOfClass:[NSNull class]])
	{
		return @"null";
	}
	else
	{
		return @"undefined";
	}
}

+ (NSString *)escapeJavaScriptString:(NSString *)string
{
	NSString *escapedString = string;

	escapedString = [escapedString stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
	escapedString = [escapedString stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];

	return escapedString;
}

- (void)evaluateFunction:(NSString *)function
{
	[self evaluateFunction:function withArguments:nil completionHandler:nil];
}

- (void)evaluateFunction:(NSString *)function withArguments:(NSArray *)arguments
{
	[self evaluateFunction:function withArguments:arguments completionHandler:nil];
}

- (void)evaluateFunction:(NSString *)function withArguments:(NSArray *)arguments completionHandler:(void (^)(id))completionHandler
{
	NSString *compiledScript = [self compiledFunctionCall:function withArguments:arguments];

	[self evaluateJavaScript:compiledScript completionHandler:completionHandler];
}

- (void)booleanByEvaluatingFunction:(NSString *)function completionHandler:(void (^)(BOOL))completionHandler
{
	[self booleanByEvaluatingFunction:function withArguments:nil completionHandler:completionHandler];
}

- (void)booleanByEvaluatingFunction:(NSString *)function withArguments:(NSArray *)arguments completionHandler:(void (^)(BOOL))completionHandler
{
	[self evaluateFunction:function withArguments:arguments completionHandler:^(id result) {
		BOOL resultBool = NO;

		if (result && [result isKindOfClass:[NSNumber class]]) {
			resultBool = [result boolValue];
		}

		if (completionHandler) {
			completionHandler(resultBool);
		}
	}];
}

- (void)stringByEvaluatingFunction:(NSString *)function completionHandler:(void (^)(NSString *))completionHandler
{
	[self stringByEvaluatingFunction:function withArguments:nil completionHandler:completionHandler];
}

- (void)stringByEvaluatingFunction:(NSString *)function withArguments:(NSArray *)arguments completionHandler:(void (^)(NSString *))completionHandler
{
	[self evaluateFunction:function withArguments:arguments completionHandler:^(id result) {
		NSString *resultString = nil;

		if (result && [result isKindOfClass:[NSString class]]) {
			resultString = result;
		}

		if (completionHandler) {
			completionHandler(resultString);
		}
	}];
}

- (void)arrayByEvaluatingFunction:(NSString *)function completionHandler:(void (^)(NSArray *))completionHandler
{
	[self arrayByEvaluatingFunction:function withArguments:nil completionHandler:completionHandler];
}

- (void)arrayByEvaluatingFunction:(NSString *)function withArguments:(NSArray *)arguments completionHandler:(void (^)(NSArray *))completionHandler
{
	[self evaluateFunction:function withArguments:arguments completionHandler:^(id result) {
		NSArray *resultArray = nil;

		if (result && [result isKindOfClass:[NSArray class]]) {
			resultArray = result;
		}

		if (completionHandler) {
			completionHandler(resultArray);
		}
	}];
}

- (void)dictionaryByEvaluatingFunction:(NSString *)function completionHandler:(void (^)(NSDictionary *))completionHandler
{
	[self dictionaryByEvaluatingFunction:function withArguments:nil completionHandler:completionHandler];
}

- (void)dictionaryByEvaluatingFunction:(NSString *)function withArguments:(NSArray *)arguments completionHandler:(void (^)(NSDictionary *))completionHandler
{
	[self evaluateFunction:function withArguments:arguments completionHandler:^(id result) {
		NSDictionary *resultDictionary = nil;

		if (result && [result isKindOfClass:[NSDictionary class]]) {
			resultDictionary = result;
		}

		if (completionHandler) {
			completionHandler(resultDictionary);
		}
	}];
}

@end

@implementation TVCLogView (TVCLogViewJavaScriptHandlerPrivate)

- (NSString *)compileJavaScriptDictionaryArgument:(NSDictionary *)objects
{
	NSMutableString *compiledScript = [NSMutableString string];

	[compiledScript appendString:@"{"];

	NSInteger lastIndex = ([objects count] - 1);

	__block NSInteger currentIndex = 0;

	[objects enumerateKeysAndObjectsUsingBlock:^(id key, id object, BOOL *stop) {
		/* Perform check to make sure the key we are using is actually a string. */
		if ([key isKindOfClass:[NSString class]] == NO) {
			LogToConsole(@"Silently ignoring non-string key: %@", NSStringFromClass([key class]));

			return;
		}

		/* Add key and value to new object. */
		NSString *keyString = [TVCLogView escapeJavaScriptString:key];

		NSString *objectString = [self compileJavaScriptGenericArgument:object];

		if (currentIndex == lastIndex) {
			[compiledScript appendFormat:@"\"%@\" : %@", keyString, objectString];
		} else {
			[compiledScript appendFormat:@"\"%@\" : %@, ", keyString, objectString];
		}

		currentIndex += 1;
	}];

	[compiledScript appendString:@"}"];

	return [compiledScript copy];
}

- (NSString *)compileJavaScriptArrayArgument:(NSArray *)objects
{
	NSMutableString *compiledScript = [NSMutableString string];

	[compiledScript appendString:@"["];

	NSInteger lastIndex = ([objects count] - 1);

	[objects enumerateObjectsUsingBlock:^(id object, NSUInteger index, BOOL *stop) {
		NSString *objectString = [self compileJavaScriptGenericArgument:object];

		if (index == lastIndex) {
			[compiledScript appendString:objectString];
		} else {
			[compiledScript appendFormat:@"%@, ", objectString];
		}
	}];

	[compiledScript appendString:@"]"];

	return [compiledScript copy];
}

- (NSString *)compileJavaScriptGenericArgument:(id)object
{
	if ([object isKindOfClass:[NSString class]])
	{
		NSString *objectEscaped = [TVCLogView escapeJavaScriptString:object];

		return [NSString stringWithFormat:@"\"%@\"", objectEscaped];
	}
	else if ([object isKindOfClass:[NSNumber class]])
	{
		if (strcmp([object objCType], @encode(BOOL)) == 0) {
			if ([object boolValue] == YES) {
				return @"true";
			} else {
				return @"false";
			}
		} else {
			return [object stringValue];
		}
	}
	else if ([object isKindOfClass:[NSArray class]])
	{
		return [self compileJavaScriptArrayArgument:object];
	}
	else if ([object isKindOfClass:[NSDictionary class]])
	{
		return [self compileJavaScriptDictionaryArgument:object];
	}
	else if ([object isKindOfClass:[NSNull class]])
	{
		return @"null";
	}
	else
	{
		return @"undefined";
	}
}

- (NSString *)compiledFunctionCall:(NSString *)function withArguments:(NSArray *)arguments
{
	NSMutableString *compiledScript = [NSMutableString string];

	NSInteger argumentCount = 0;

	if ( arguments) {
		argumentCount = [arguments count];

		[arguments enumerateObjectsUsingBlock:^(id object, NSUInteger objectIndex, BOOL *stop)
		 {
			 NSString *objectString = [self compileJavaScriptGenericArgument:object];

			 [compiledScript appendFormat:@"var _argument_%ld_ = %@;\n", objectIndex, objectString];
		 }];
	}

	[compiledScript appendFormat:@"%@(", function];

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

- (id)webScriptObjectToCommon:(WebScriptObject *)object
{
	/* Required sanity checks */
	if ([self isUsingWebKit2]) {
		NSAssert(NO, @"Cannot use feature when WebKit2 is in use");
	}

	if (object == nil) {
		return nil;
	}

	/* Context information */
	WebFrame *webViewFrame = [[self webViewBacking] mainFrame];

	JSGlobalContextRef jsContextRef = [webViewFrame globalContext];

	/* Perform conversion */
	return [object toCommonInContext:jsContextRef];
}

@end
