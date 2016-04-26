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

/* Defines for operating system detection. */
#define TXLoadMacOSVersionSpecificFeatures		1

#if TXLoadMacOSVersionSpecificFeatures
	#if defined(AVAILABLE_MAC_OS_X_VERSION_10_11_AND_LATER)
		#define TXSystemIsOSXElCapitanOrLater
	#endif
#endif

/* Shortcut defines. */
#define RZAnimationCurrentContext()				[NSAnimationContext	currentContext]
#define RZAppearaneCurrentController()			[NSAppearance currentAppearance]
#define RZAppleEventManager()					[NSAppleEventManager sharedAppleEventManager]
#define RZCurrentCalender()						[NSCalendar currentCalendar]
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
#define RZUserNotificationCenter()				[NSUserNotificationCenter defaultUserNotificationCenter]
#define RZWorkspace()							[NSWorkspace sharedWorkspace]
#define RZWorkspaceNotificationCenter()			[RZWorkspace() notificationCenter]

/* Misc. */
#define NSInvertedComparisonResult(c)			((c) * (-1))

#define NSIsCurrentThreadMain()					[[NSThread currentThread] isEqual:[NSThread mainThread]]

/* The reference date is the date & time of the first commit to the
 Textual repo. Textual existed before then, of course, but the date
 will remain as the official reference date for its birthday. */
/* The date decodes to July 23, 2010 03:53:00 AM */
#define TXBirthdayReferenceDate					1279871580.000000

/* typedef for filesize information. */
typedef unsigned long long						TXUnsignedLongLong;

/* Empty block for cleaner paramaters. */
typedef void (^TXEmtpyBlockDataType)(void);

/* Include a forced lifespan for beta builds. */
// #define TEXTUAL_BUILT_WITH_FORCED_BETA_LIFESPAN 1

/* Include Off-the-Record Messaging (OTR) support */
#define TEXTUAL_BUILT_WITH_ADVANCED_ENCRYPTION 1

/* Standard out logging. */
/* It is recommended to always use these calls above plain-ol' NSLog. */
#ifdef DEBUG
	#define DebugLogToConsole(fmt, ...)			LogToConsole(fmt, ##__VA_ARGS__);
#else
	#define DebugLogToConsole(fmt, ...)			if ([masterController() debugModeIsOn]) {			\
													LogToConsole(fmt, ##__VA_ARGS__);				\
												}
#endif

/* Deprecation and symbol visibility. */
#define TEXTUAL_EXTERN							extern

#define TEXTUAL_DEPRECATED(reason)				COCOA_EXTENSIONS_DEPRECATED(reason)

#define TEXTUAL_IGNORE_DEPRECATION_BEGIN		_Pragma("clang diagnostic push")									\
												_Pragma("clang diagnostic ignored \"-Wdeprecated-declarations\"")

#define TEXTUAL_IGNORE_DEPRECATION_END			_Pragma("clang diagnostic pop")

/* Defines for script support instead of importing the
 entire Carbon framework for three items. */
#ifndef kASAppleScriptSuite
	#define kASAppleScriptSuite 'ascr'
#endif

#ifndef kASSubroutineEvent
	#define kASSubroutineEvent 'psbr'
#endif

#ifndef keyASSubroutineName
	#define keyASSubroutineName 'snam'
#endif

/* @end */
