/* *********************************************************************

        Copyright (c) 2010 - 2015 Codeux Software, LLC
     Please see ACKNOWLEDGEMENT for additional information.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions
 are met:

 * Redistributions of source code must retain the above copyright
   notice, this list of conditions and the following disclaimer.
 * Redistributions in binary form must reproduce the above copyright
   notice, this list of conditions and the following disclaimer in the
   documentation and/or other materials provided with the distribution.
 * Neither the name of "Codeux Software, LLC", nor the names of its 
   contributors may be used to endorse or promote products derived 
   from this software without specific prior written permission.

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

#import "WebScriptObjectHelperPrivate.h"

NS_ASSUME_NONNULL_BEGIN

@implementation WebScriptObject (TXWebScriptObjectHelper)

- (nullable id)toCommonInContext:(JSContextRef)jsContextRef
{
	NSParameterAssert(jsContextRef != NULL);

	JSObjectRef jsObjectRef = [self JSObject];

	/* The object is useless if it is a function */
	if (JSObjectIsFunction(jsContextRef, jsObjectRef)) {
		LogToConsoleDebug("Ignoring a JSObject that is a function");

		return nil;
	}

	/* If the object is an array, then parse it as such */
	if ([WebScriptObject jsObjectIsArray:jsObjectRef inContext:jsContextRef]) {
		NSNumber *arrayLengthObject = [self valueForKey:@"length"];

		NSUInteger arrayLength = arrayLengthObject.unsignedIntegerValue;

		NSMutableArray *scriptArray = [NSMutableArray arrayWithCapacity:arrayLength];

		for (NSUInteger i = 0; i < arrayLength; i++) {
			id item = [self webScriptValueAtIndex:(unsigned)i];

			if ([item isKindOfClass:[WebScriptObject class]]) {
				item = [item toCommonInContext:jsContextRef];
			} else if ([item isKindOfClass:[WebUndefined class]]) {
				item = nil;
			}

			if (item) {
				[scriptArray addObject:item];
			} else {
				[scriptArray addObject:[NSNull null]];
			}
		}

		return scriptArray;
	}

	/* If the object is an object (dictionary), then parse it as such */
	if ([WebScriptObject jsObjectIsObject:jsObjectRef inContext:jsContextRef]) {
		JSPropertyNameArrayRef objectProperties = JSObjectCopyPropertyNames(jsContextRef, jsObjectRef);

		size_t objectPropertiesCount = JSPropertyNameArrayGetCount(objectProperties);

		NSMutableDictionary *scriptDictionary = [NSMutableDictionary dictionaryWithCapacity:(NSUInteger)objectPropertiesCount];

		for (NSUInteger i = 0; i < objectPropertiesCount; i++) {
			JSStringRef propertyName = JSPropertyNameArrayGetNameAtIndex(objectProperties, i);

			NSString *propertyNameCocoa = (__bridge_transfer NSString *)JSStringCopyCFString(kCFAllocatorDefault, propertyName);

			id item = [self valueForKey:propertyNameCocoa];

			if ([item isKindOfClass:[WebScriptObject class]]) {
				item = [item toCommonInContext:jsContextRef];
			} else if ([item isKindOfClass:[WebUndefined class]]) {
				item = nil;
			}

			if (item) {
				scriptDictionary[propertyNameCocoa] = item;
			} else {
				scriptDictionary[propertyNameCocoa] = [NSNull null];
			}
		}

		return scriptDictionary;
	}

	return nil;
}

+ (BOOL)jsObjectIsArray:(JSObjectRef)jsObjectRef inContext:(JSContextRef)jsContextRef
{
	NSParameterAssert(jsObjectRef != NULL);
	NSParameterAssert(jsContextRef != NULL);

	JSObjectRef jsGlobalObjectRef = JSContextGetGlobalObject(jsContextRef);

	JSStringRef arrayString = JSStringCreateWithUTF8CString("Array");

	JSObjectRef arrayPrototype = (JSObjectRef)JSObjectGetProperty(jsContextRef, jsGlobalObjectRef, arrayString, NULL);

	JSStringRelease(arrayString);

	return JSValueIsInstanceOfConstructor(jsContextRef, jsObjectRef, arrayPrototype, NULL);
}

+ (BOOL)jsObjectIsObject:(JSObjectRef)jsObjectRef inContext:(JSContextRef)jsContextRef
{
	NSParameterAssert(jsObjectRef != NULL);
	NSParameterAssert(jsContextRef != NULL);

	JSObjectRef jsGlobalObjectRef = JSContextGetGlobalObject(jsContextRef);

	JSStringRef objectString = JSStringCreateWithUTF8CString("Object");

	JSObjectRef objectPrototype = (JSObjectRef)JSObjectGetProperty(jsContextRef, jsGlobalObjectRef, objectString, NULL);

	JSStringRelease(objectString);

	return JSValueIsInstanceOfConstructor(jsContextRef, jsObjectRef, objectPrototype, NULL);
}

@end

NS_ASSUME_NONNULL_END
