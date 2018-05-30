/* *********************************************************************
 *                  _____         _               _
 *                 |_   _|____  _| |_ _   _  __ _| |
 *                   | |/ _ \ \/ / __| | | |/ _` | |
 *                   | |  __/>  <| |_| |_| | (_| | |
 *                   |_|\___/_/\_\\__|\__,_|\__,_|_|
 *
 * Copyright (c) 2010 - 2015 Codeux Software, LLC & respective contributors.
 *       Please see Acknowledgements.pdf for additional information.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions
 * are met:
 *
 *  * Redistributions of source code must retain the above copyright
 *    notice, this list of conditions and the following disclaimer.
 *  * Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *  * Neither the name of Textual, "Codeux Software, LLC", nor the
 *    names of its contributors may be used to endorse or promote products
 *    derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
 * ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
 * OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 * HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
 * LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
 * OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
 * SUCH DAMAGE.
 *
 *********************************************************************** */

NS_ASSUME_NONNULL_BEGIN

#define DESIGNATED_INITIALIZER_EXCEPTION	\
	NSAssert(NO, @"-init called in class with a designated initializer");

#define DESIGNATED_INITIALIZER_EXCEPTION_BODY_BEGIN							\
	_Pragma("clang diagnostic push")										\
	_Pragma("clang diagnostic ignored \"-Wobjc-designated-initializers\"")

#define DESIGNATED_INITIALIZER_EXCEPTION_BODY_END	\
	_Pragma("clang diagnostic pop")

#define DESIGNATED_INITIALIZER_EXCEPTION_BODY			\
	DESIGNATED_INITIALIZER_EXCEPTION_BODY_BEGIN			\
														\
	- (instancetype)init								\
	{													\
		DESIGNATED_INITIALIZER_EXCEPTION				\
														\
		return nil;										\
	}													\
														\
	DESIGNATED_INITIALIZER_EXCEPTION_BODY_END

#define ClassWithDesignatedInitializerInitMethod	DESIGNATED_INITIALIZER_EXCEPTION_BODY

#define ObjectIsAlreadyInitializedAssert			\
	NSAssert((self->_objectInitialized == NO),		\
		@"Object is already initialized");

@interface NSObject (TXObjectHelper)
- (void)applicationDidFinishLaunching;

- (void)preferencesChanged;

- (void)prepareInitialState;
- (void)prepareForApplicationTermination;
- (void)prepareForPermanentDestruction;

+ (void)preferencesChanged;

+ (void)prepareInitialState;
+ (void)prepareForApplicationTermination;
+ (void)prepareForPermanentDestruction;
@end

NS_ASSUME_NONNULL_END
