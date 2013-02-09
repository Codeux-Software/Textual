/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2013 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

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

/* Imports from Carbon Headers. */
#ifndef kASAppleScriptSuite
	#define kASAppleScriptSuite 'ascr'
#endif

#ifndef kASSubroutineEvent
	#define kASSubroutineEvent 'psbr'
#endif

#ifndef keyASSubroutineName
	#define keyASSubroutineName 'snam'
#endif

/* Availability Macros. */
#define TXLoadMacOSVersionSpecificFeatures 1

#if TXLoadMacOSVersionSpecificFeatures
	#if defined(AVAILABLE_MAC_OS_X_VERSION_10_8_AND_LATER) 
		#define TXSystemIsMacOSMountainLionOrNewer
	#endif

	#if defined(AVAILABLE_MAC_OS_X_VERSION_10_7_AND_LATER) 
		#define TXSystemIsMacOSLionOrNewer
	#endif
#endif

#define NSAppKitVersionNumber10_6		1038
#define NSAppKitVersionNumber10_7		1138
#define NSAppKitVersionNumber10_7_2		1138.23

#define PointerIsEmpty(s)				(s == NULL || s == nil)
#define PointerIsNotEmpty(s)			(s != NULL && s != nil)

#ifdef TXSystemIsMacOSLionOrNewer
	#define TXNativeRegularExpressionAvailable
#endif

#ifdef TXSystemIsMacOSMountainLionOrNewer
	#define TXUnsupervisedScriptFolderAvailable
	#define TXFoundationBasedUUIDAvailable
#endif

//#define TXForceNativeNotificationCenterDispatch		— Force notification center use regardless of Growl's installation.

#define LogToConsole(fmt, ...) NSLog([@"%s [Line %d]: " stringByAppendingString:fmt], \
															__PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);

#ifdef DEBUG
	#define DebugLogToConsole(fmt, ...) LogToConsole(fmt, ##__VA_ARGS__);
#else
	#define DebugLogToConsole(...)
#endif

/* Establish Common Pointers. */
#define _NSAnimationCurrentContext()			[NSAnimationContext					currentContext]
#define _NSAppleEventManager()					[NSAppleEventManager				sharedAppleEventManager]
#define _NSDistributedNotificationCenter()		[NSDistributedNotificationCenter	defaultCenter]
#define _NSFileManager()						[NSFileManager						defaultManager]
#define _NSFontManager()						[NSFontManager						sharedFontManager]
#define _NSGraphicsCurrentContext()				[NSGraphicsContext					currentContext]
#define _NSMainScreen()							[NSScreen							mainScreen]
#define _NSNotificationCenter()					[NSNotificationCenter				defaultCenter]
#define _NSPasteboard()							[NSPasteboard						generalPasteboard]
#define _NSProcessInfo()						[NSProcessInfo						processInfo]
#define _NSSharedApplication()					[NSApplication						sharedApplication]
#define _NSSpellChecker()						[NSSpellChecker						sharedSpellChecker]
#define _NSUserDefaults()						[NSUserDefaults						standardUserDefaults]
#define _NSUserDefaultsController()				[NSUserDefaultsController			sharedUserDefaultsController]
#define _NSWorkspace()							[NSWorkspace						sharedWorkspace]
#define _NSWorkspaceNotificationCenter()		[_NSWorkspace()						notificationCenter]

#ifdef TXNativeNotificationCenterAvailable
	#define _NSUserNotificationCenter()				[NSUserNotificationCenter defaultUserNotificationCenter]
#endif

/* Miscellaneous functions to handle small tasks. */
#define BOOLReverseValue(b)					((b == YES) ? NO : YES)
#define BOOLValueFromObject(b)				PointerIsNotEmpty(b)
#define CFItemRefToID(s)					(id)s
#define NSDissimilarObjects(o,n)			(o != n)

#define TEXTUAL_EXTERN                      __attribute__((visibility("default")))
#define TEXTUAL_DEPRECATED					__attribute__((deprecated))

#define TEXTUAL_DEPRECATED_ASSERT			NSAssert1(NO, @"Deprecated Method: %s", __PRETTY_FUNCTION__);
#define TEXTUAL_DEPRECATED_ASSERT_C			NSCAssert1(NO, @"Deprecated Method: %s", __PRETTY_FUNCTION__);

/* Item types. */
typedef double				TXNSDouble;
typedef unsigned long long	TXFSLongInt; // filesizes

/* Everything else. */
#define TXDeveloperEnvironmentToken			@"TextualDeveloperEnvironment"
