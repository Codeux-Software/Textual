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

@implementation TVCLogView

NSString * const TVCLogViewCommonUserAgentString = @"Textual/1.0 (+https://help.codeux.com/textual/Inline-Media-Scanner-User-Agent.kb)";

- (void)keyDown:(NSEvent *)e
{
	if (self.keyDelegate) {
		NSUInteger m = [e modifierFlags];
		
		BOOL cmd = (m & NSCommandKeyMask);
		BOOL alt = (m & NSAlternateKeyMask);
		BOOL ctrl = (m & NSControlKeyMask);
		
		if (ctrl == NO && alt == NO && cmd == NO) {
			if ([self.keyDelegate respondsToSelector:@selector(logViewKeyDown:)]) {
				[self.keyDelegate logViewKeyDown:e];
			}
			
			return;
		}
	}
	
	[super keyDown:e];
}

- (BOOL)maintainsInactiveSelection
{
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSURL *fileURL = [NSURL URLFromPasteboard:[sender draggingPasteboard]];

	if (fileURL) {
		NSString *filename = [fileURL relativePath];
		
		if ([self.draggingDelegate respondsToSelector:@selector(logViewRecievedDropWithFile:)]) {
			[self.draggingDelegate logViewRecievedDropWithFile:filename];
		}
	}
	
	return NO;
}

- (NSString *)contentString
{
	NSString *contentString = [self executeCommand:@"Textual.documentHTML"];

	return contentString;
}

- (BOOL)hasSelection
{
	NSString *selection = [self selection];

	return (NSObjectIsEmpty(selection) == NO);
}

- (NSString *)selection
{
	NSString *selection = [self executeCommand:@"Textual.currentSelection"];

	return selection;
}

- (void)clearSelection
{
	(void)[self executeCommand:@"Textual.clearSelection"];
}

@end

@implementation TVCLogView (TVCLogViewJavaScriptHandler)

- (BOOL)scriptingIsAvailable
{
	WebScriptObject *scriptObject = [self windowScriptObject];

	if (scriptObject == nil || [scriptObject isKindOfClass:[WebUndefined class]]) {
		return NO;
	} else {
		return YES;
	}
}

- (id)executeJavaScript:(NSString *)code
{
	WebScriptObject *scriptObject = [self windowScriptObject];

	if (scriptObject == nil || [scriptObject isKindOfClass:[WebUndefined class]]) {
		return nil;
	}

	id scriptResult = [scriptObject evaluateWebScript:code];

	if (scriptResult == nil || [scriptResult isKindOfClass:[WebUndefined class]]) {
		return nil;
	}

	return scriptResult;
}

- (NSString *)escapeJavaScriptString:(NSString *)string
{
	return [string stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
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

- (id)executeCommand:(NSString *)command
{
	return [self executeCommand:command withArguments:nil];
}

- (id)executeCommand:(NSString *)command withArguments:(NSArray *)arguments
{
	NSString *compiledScript = [self compiledCommandCall:command withArguments:arguments];

	return [self executeJavaScript:compiledScript];
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

	id arrayLengthObject = [scriptResult valueForKey:@"length"];

	if (arrayLengthObject == nil || [arrayLengthObject isKindOfClass:[NSNumber class]] == NO) {
		return nil;
	}

	NSUInteger arrayLength = [arrayLengthObject unsignedIntegerValue];

	NSMutableArray *scriptArray = [NSMutableArray arrayWithCapacity:arrayLength];

	for (NSUInteger i = 0; i < arrayLength; i++) {
		id item = [scriptResult webScriptValueAtIndex:(unsigned)i];

		[scriptArray addObject:item];
	}

	return [scriptArray copy];
}

@end
