// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 08, 2012

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

/* Availability Macros */
#define TXLoadMacOSLibraries 1

#if TXLoadMacOSLibraries
	#if defined(AVAILABLE_MAC_OS_X_VERSION_10_8_AND_LATER) 
		#define TXMacOSMountainLionOrNewer
	#endif

	#if defined(AVAILABLE_MAC_OS_X_VERSION_10_7_AND_LATER) 
		#define TXMacOSLionOrNewer
	#endif
#endif

#define NSAppKitVersionNumber10_6		1038
#define NSAppKitVersionNumber10_7		1138
#define NSAppKitVersionNumber10_7_2		1138.23

#define PointerIsEmpty(s)				(s == NULL || s == nil)
#define PointerIsNotEmpty(s)			(s != NULL && s != nil)

#ifdef TXMacOSLionOrNewer
	#define TXNativeRegularExpressionAvailable
#endif

#ifdef TXMacOSMountainLionOrNewer
	#define TXNativeNotificationCenterAvailable
	#define TXUserScriptsFolderAvailable
	#define TXFoundationBasedUUIDAvailable
#endif

/* http://stackoverflow.com/questions/969130/nslog-tips-and-tricks */
#ifdef DEBUG
	#define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
	#define DLog(...)
#endif

/* Establish Common Pointers */
#define _NSMainScreen()							[NSScreen mainScreen]
#define _NSFileManager()						[NSFileManager defaultManager]
#define _NSPasteboard()							[NSPasteboard generalPasteboard]
#define _NSFontManager()						[NSFontManager sharedFontManager]
#define _NSGraphicsCurrentContext()				[NSGraphicsContext currentContext]
#define _NSNotificationCenter()					[NSNotificationCenter defaultCenter]
#define _NSWorkspace()							[NSWorkspace sharedWorkspace]
#define _NSWorkspaceNotificationCenter()		[_NSWorkspace() notificationCenter]
#define _NSDistributedNotificationCenter()		[NSDistributedNotificationCenter defaultCenter]
#define _NSAppleEventManager()					[NSAppleEventManager sharedAppleEventManager]
#define _NSUserDefaults()						[NSUserDefaults standardUserDefaults]
#define _NSUserDefaultsController()				[NSUserDefaultsController sharedUserDefaultsController]
#define _NSSpellChecker()						[NSSpellChecker sharedSpellChecker]

#ifdef TXNativeNotificationCenterAvailable
	#define _NSUserNotificationCenter()				[NSUserNotificationCenter defaultUserNotificationCenter]
#endif

/* Miscellaneous functions to handle small tasks. */
#define CFItemRefToID(s)					(id)s
#define BOOLReverseValue(b)					((b == YES) ? NO : YES)
#define BOOLValueFromObject(b)				PointerIsNotEmpty(b)
#define NSDissimilarObjects(o,n)			(o != n)

#define TEXTUAL_EXTERN                      __attribute__((visibility("default")))

/* Item types */
typedef double				TXNSDouble;
typedef unsigned long long	TXFSLongInt; // filesizes

/* Number Handling */
#define NSNumberWithBOOL(b)					[NSNumber numberWithBool:b]
#define NSNumberWithLong(l)					[NSNumber numberWithLong:l]
#define NSNumberWithInteger(i)				[NSNumber numberWithInteger:i]
#define NSNumberWithLongLong(l)				[NSNumber numberWithLongLong:l]
#define NSNumberWithDouble(d)				[NSNumber numberWithDouble:d]
#define NSNumberInRange(n,s,e)				(n >= s && n <= e)

/* Everything Else */
#define NSStringEmptyPlaceholder			@""
#define NSStringNewlinePlaceholder			@"\n"
#define NSStringWhitespacePlaceholder		@" "

#define TXDeveloperEnvironmentToken			@"TextualDeveloperEnvironment"
