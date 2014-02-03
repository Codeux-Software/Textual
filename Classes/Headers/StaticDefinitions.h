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

#define TXLoadMacOSVersionSpecificFeatures		1

#ifndef kASAppleScriptSuite
	#define kASAppleScriptSuite 'ascr'
#endif

#ifndef kASSubroutineEvent
	#define kASSubroutineEvent 'psbr'
#endif

#ifndef keyASSubroutineName
	#define keyASSubroutineName 'snam'
#endif

#if TXLoadMacOSVersionSpecificFeatures
 	#if defined(AVAILABLE_MAC_OS_X_VERSION_10_9_AND_LATER)
 		#define TXSystemIsMacOSMavericksOrNewer
 	#endif
#endif

#define NSAppKitVersionNumber10_6	1038
#define NSAppKitVersionNumber10_7	1138
#define NSAppKitVersionNumber10_7_2 1138.23
#define NSAppKitVersionNumber10_7_3 1138.32
#define NSAppKitVersionNumber10_7_4 1138.47
#define NSAppKitVersionNumber10_8	1187

#define LogToConsole(fmt, ...) NSLog([@"%s [Line %d]: " stringByAppendingString:fmt], __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

#ifdef DEBUG
	#define DebugLogToConsole(fmt, ...)			LogToConsole(fmt, ##__VA_ARGS__);
#else
	#define DebugLogToConsole(fmt, ...)			if (self.masterController.debugModeOn) {		\
													LogToConsole(fmt, ##__VA_ARGS__);			\
												}
#endif

/* Shortcut defines. */
#define RZAnimationCurrentContext()				[NSAnimationContext	currentContext]
#define RZAppleEventManager()					[NSAppleEventManager sharedAppleEventManager]
#define RZCurrentRunLoop()						[NSRunLoop currentRunLoop]
#define RZDistributedNotificationCenter()		[NSDistributedNotificationCenter defaultCenter]
#define RZFileManager()							[NSFileManager defaultManager]
#define RZFontManager()							[NSFontManager sharedFontManager]
#define RZGraphicsCurrentContext()				[NSGraphicsContext currentContext]
#define RZMainBundle()							[NSBundle mainBundle]
#define RZMainOperationQueue()					[NSOperationQueue mainQueue]
#define RZMainRunLoop()							[NSRunLoop mainRunLoop]
#define RZMainScreen()							[NSScreen mainScreen]
#define RZNotificationCenter()					[NSNotificationCenter defaultCenter]
#define RZPasteboard()							[NSPasteboard generalPasteboard]
#define RZProcessInfo()							[NSProcessInfo processInfo]
#define RZRunningApplication()					[NSRunningApplication currentApplication]
#define RZSharedApplication()					[NSApplication sharedApplication]
#define RZSpellChecker()						[NSSpellChecker	sharedSpellChecker]
#define RZUbiquitousKeyValueStore()				[NSUbiquitousKeyValueStore defaultStore]
#define RZUserDefaults()						[NSUserDefaults	standardUserDefaults]
#define RZUserDefaultsController()				[NSUserDefaultsController sharedUserDefaultsController]
#define RZUserNotificationCenter()				[NSUserNotificationCenter defaultUserNotificationCenter]
#define RZWorkspace()							[NSWorkspace sharedWorkspace]
#define RZWorkspaceNotificationCenter()			[RZWorkspace() notificationCenter]

/* Lazy-man defines. */
#define PointerIsEmpty(s)						((s) == NULL || (s) == nil)
#define PointerIsNotEmpty(s)					((s) != NULL && (s) != nil)

#define BOOLReverseValue(b)						((b == YES) ? NO : YES)
#define BOOLValueFromObject(b)					PointerIsNotEmpty(b)
#define CFSafeRelease(s)						if ((s) != NULL) { CFRelease((s)); }
#define NSDissimilarObjects(o,n)				((o) != (n))

#define NSAssertReturn(c)						if ((c) == NO) { return; }
#define NSAssertReturnR(c, r)					if ((c) == NO) { return (r); }
#define NSAssertReturnLoopContinue(c)			if ((c) == NO) { continue; }
#define NSAssertReturnLoopBreak(c)				if ((c) == NO) { break; }

#define NSObjectIsEmptyAssert(o)				if (NSObjectIsEmpty(o)) { return; }
#define NSObjectIsEmptyAssertReturn(o, r)		if (NSObjectIsEmpty(o)) { return (r); }
#define NSObjectIsEmptyAssertLoopContinue(o)	if (NSObjectIsEmpty(o)) { continue; }
#define NSObjectIsEmptyAssertLoopBreak(o)		if (NSObjectIsEmpty(o)) { break; }

#define NSObjectIsNotEmptyAssert(o)					if (NSObjectIsNotEmpty(o)) { return; }
#define NSObjectIsNotEmptyAssertReturn(o, r)		if (NSObjectIsNotEmpty(o)) { return (r); }
#define NSObjectIsNotEmptyAssertLoopContinue(o)		if (NSObjectIsNotEmpty(o)) { continue; }
#define NSObjectIsNotEmptyAssertLoopBreak(o)		if (NSObjectIsNotEmpty(o)) { break; }

#define PointerIsEmptyAssert(o)					if (PointerIsEmpty(o)) { return; }
#define PointerIsEmptyAssertReturn(o, r)		if (PointerIsEmpty(o)) { return (r); }
#define PointerIsEmptyAssertLoopContinue(o)		if (PointerIsEmpty(o)) { continue; }
#define PointerIsEmptyAssertLoopBreak(o)		if (PointerIsEmpty(o)) { break; }

#define PointerIsNotEmptyAssert(o)					if (PointerIsNotEmpty(o)) { return; }
#define PointerIsNotEmptyAssertReturn(o, r)			if (PointerIsNotEmpty(o)) { return (r); }
#define PointerIsNotEmptyAssertLoopContinue(o)		if (PointerIsNotEmpty(o)) { continue; }
#define PointerIsNotEmptyAssertLoopBreak(o)			if (PointerIsNotEmpty(o)) { break; }

#define NSObjectIsKindOfClassAssert(o,c)				if ([(o) isKindOfClass:[c class]] == NO) { return; }
#define NSObjectIsKindOfClassAssertReturn(o, c, r)		if ([(o) isKindOfClass:[c class]] == NO) { return (r); }
#define NSObjectIsKindOfClassAssertContinue(o, c)		if ([(o) isKindOfClass:[c class]] == NO) { continue; }
#define NSObjectIsKindOfClassAssertBreak(o,c)			if ([(o) isKindOfClass:[c class]] == NO) { break; }

#define NSInvertedComparisonResult(c)			((c) * (-1))

#define NSIsCurrentThreadMain()					[[NSThread currentThread] isEqual:[NSThread mainThread]]

/* Deprecation and symbol visibility. */
#define TEXTUAL_EXTERN							__attribute__((visibility("default")))
#define TEXTUAL_DEPRECATED						__attribute__((deprecated))

#define TEXTUAL_DEPRECATED_ASSERT				NSAssert1(NO, @"Deprecated Method: %s", __PRETTY_FUNCTION__);
#define TEXTUAL_DEPRECATED_ASSERT_C				NSCAssert1(NO, @"Deprecated Method: %s", __PRETTY_FUNCTION__);

#define TXDeveloperEnvironmentToken				@"TextualDeveloperEnvironment"

/* The reference date is the date & time of the first commit to the
 Textual repo. Textual existed before then, of course, but the date
 will remain as the official reference date for its birthday. */

#define TXBirthdayReferenceDate		1279871580.000000 // July 23, 2010 03:53:00 AM

/* nweak and uweak are pretty useless defines. They are
 only defined to make a long list of properties easier to 
 read by making the types the same length. Easier to follow
 a property list when all the types are aligned in a line.
 
 It doesn't make sense. I know. */

#define nweak									weak
#define uweak									unsafe_unretained

/* Just like nweak and uweak, these are useless, but hey, whatever. */
typedef unsigned long long						TXFSLongInt;

/* Whether to force disable app nap using NSProcessInfo */
// #define TEXTUAL_BUILT_WITH_APP_NAP_DISABLED

/* Whether to build Textual with Core Data support. */
/* Disabling it will still use Core Data model defined for 
 TVCLogControllerHistoricLogFile, but it will not write 
 or maintain any managed object in a file or in memory. */
// #define TEXTUAL_BUILT_WITH_CORE_DATA_DISABLED

/* @end */
