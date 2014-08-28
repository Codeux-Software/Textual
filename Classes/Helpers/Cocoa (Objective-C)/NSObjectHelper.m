/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2014 Codeux Software & respective contributors.
     Please see Acknowledgements.pdf for additional information.

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

#import <objc/runtime.h>

@implementation NSObject (TXObjectHelper)

- (id)performSelector:(SEL)aSelector withArguments:(NSArray *)arguments returnsPrimitives:(BOOL)returnsPrimitives usesTypeChecking:(BOOL)usesTypeChecking error:(NSArray **)errorMessages
{
	/* Define context. */
	NSMutableArray *errorMessageBuffer = [NSMutableArray array];
	
	id finalResult = nil;
	
	BOOL safeToPerform = YES;

#define _insertError(isWarning, errorMessage)			[errorMessageBuffer addObject:@{@"isWarning" : @((isWarning)), @"errorMessage" : (errorMessage)}];
	
	/* Make sure we even have a selector to perform. */
	if (aSelector == NULL) {
		_insertError(NO, @"Cannot perform selector with a selector value of NULL")
	} else {
		/* It is important to check this. */
		if ([self isKindOfClass:[WebUndefined class]]) {
			_insertError(NO, ([NSString stringWithFormat:@"Error performing selector %@ because the owning object is undefined.", NSStringFromSelector(aSelector)]));
			
			safeToPerform = NO;
		}
		
		if (safeToPerform) {
			/* Get method signature and make sure that it even exists. */
			NSMethodSignature *signature = [self methodSignatureForSelector:aSelector];
			
			if (signature == nil) {
				_insertError(NO, ([NSString stringWithFormat:@"The method named %@ is not declared by %@", NSStringFromSelector(aSelector), NSStringFromClass([self class])]));
			
				safeToPerform = NO;
			}
			
			if (safeToPerform) {
				/* Check the argument count of the method we are invoking. */
				NSUInteger realArgumentCount = ([signature numberOfArguments] - 2); // See docs for reason behind the minus
				NSUInteger actualArgumentCount = 0;
				
				if (arguments) {
					actualArgumentCount = [arguments count];
				}
				
				if (NSDissimilarObjects(actualArgumentCount, realArgumentCount)) {
					_insertError(NO, ([NSString stringWithFormat:@"Error performing %@ on %@: The number of arguments supplied does not match the expected number of arguments that %@ expects. Expected value: %lu", NSStringFromSelector(aSelector), NSStringFromClass([self class]), NSStringFromSelector(aSelector), realArgumentCount]));
				
					safeToPerform = NO;
				}
			}
			
			/* Maybe continue. */
			if (safeToPerform) {
				/* Get return type and may not process event depending on if the return
				 type is not an object if returnsPrimitives is NO. */
				const char *methodReturnType = [signature methodReturnType];
				
				BOOL methodReturnsVoid = (*methodReturnType == _C_VOID);
				
				if (returnsPrimitives == NO) {
					if (*methodReturnType == _C_ID ||
						*methodReturnType == _C_CLASS ||
						*methodReturnType == _C_SEL ||
						 methodReturnsVoid)
					{
						; // Safe to continue…
					} else {
						_insertError(NO, ([NSString stringWithFormat:@"Error performing %1$@ on %2$@: Return type of %1$@ is a primitive but the value of returnsPrimitives is set to NO", NSStringFromSelector(aSelector), NSStringFromClass([self class])]));
						
						safeToPerform = NO;
					}
				}
				
				/* Maybe continue. */
				if (safeToPerform) {
					/* Define basic context of invocation. */
					void *primitiveReturnValue;
					
					NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
					
					[invocation setTarget:self];
					[invocation setSelector:aSelector];
					
					/* If arguments are supplied, then we begin processing them. */
					if (arguments) {
						NSInteger argumentIndex = 2; // 0 and 1 are reserved
						
						/* As we are processing an array of arguments we expect one of two things:
						 The supplied value will be a subset of NSValue or it will be another type
						 of object. When it is a subset of NSValue, we use strict type checking. */
						for (__unsafe_unretained id argument in arguments) {
							if ([argument isKindOfClass:[NSValue class]] ||
								[argument isKindOfClass:[NSNumber class]])
							{
								/* Perform type checking. */
								const char *expectedArgumentValue = [signature getArgumentTypeAtIndex:argumentIndex];
								
								const char *actualArgumentValue = [argument objCType];
								
								if (*expectedArgumentValue == *actualArgumentValue) {
									; // Safe to continue…
								} else {
									if (usesTypeChecking) {
										_insertError(NO, ([NSString stringWithFormat:@"Error: Performing %@ on %@: Mismatched argument type at index %lu — Expected type token: '%@', actual type token: '%@'", NSStringFromSelector(aSelector), NSStringFromClass([self class]), argumentIndex, @(expectedArgumentValue), @(actualArgumentValue)]));
										
										safeToPerform = NO;
									} else {
										_insertError(YES, ([NSString stringWithFormat:@"Warning: Performing %@ on %@: Mismatched argument type at index %lu — Expected type token: '%@', actual type token: '%@' — Will send values anyways as strict type checking is disabled. The result of this mismatched type is undefined.", NSStringFromSelector(aSelector), NSStringFromClass([self class]), argumentIndex, @(expectedArgumentValue), @(actualArgumentValue)]));
									}
								}
								
								/* Copy value as argument. */
								NSUInteger bufferSize = 0;
							
								NSGetSizeAndAlignment(actualArgumentValue, &bufferSize, NULL);
							
								void *argumentValue = malloc(bufferSize);
								
								[argument getValue:argumentValue];
								
								[invocation setArgument:argumentValue atIndex:argumentIndex];
							
								free(argumentValue);
							} else {
								/* Value is a normal object so provide a reference to it. */
								[invocation setArgument:&argument atIndex:argumentIndex];
							}
							
							argumentIndex += 1;
						}
					}
					
					/* If everything checked out okay, then we can continue. */
					if (safeToPerform) {
						[invocation retainArguments];
						[invocation invoke];
						
						if (methodReturnsVoid == NO) {
							[invocation getReturnValue:&primitiveReturnValue];
							
							finalResult = [NSValue valueWithPrimitive:primitiveReturnValue withType:methodReturnType];
						}
					}
				}
			}
		}
	}
	
	/* Copy any errors over. */
	if ( errorMessages) {
		*errorMessages = [errorMessageBuffer copy];
	}

	/* Return default value. */
	return finalResult;
	
#undef _insertError
}

@end
