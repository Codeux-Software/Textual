/* Availability Macros */
#define _LOAD_MAC_OS_LION_LIBRARIES 1
//#define _USES_MODERN_REGULAR_EXPRESSION

#if _LOAD_MAC_OS_LION_LIBRARIES
	#if defined(MAC_OS_X_VERSION_10_7) 
		#if MAC_OS_X_VERSION_MAX_ALLOWED >= MAC_OS_X_VERSION_10_7
			#define _RUNNING_MAC_OS_LION
		#endif	
	#endif
#endif

#ifndef NSAppKitVersionNumber10_6
	#define NSAppKitVersionNumber10_6 1038
#endif

/* Textual Specific Frameworks */
#ifdef LinkTextualIRCFrameworks
	#import <AutoHyperlinks/AutoHyperlinks.h>
	#import <BlowfishEncryption/BlowfishEncryption.h>
#endif

/* Establish Common Pointers */
#define _NSWorkspace()							[NSWorkspace sharedWorkspace]
#define _NSPasteboard()							[NSPasteboard generalPasteboard]
#define _NSFileManager()						[NSFileManager defaultManager]
#define _NSFontManager()						[NSFontManager sharedFontManager]
#define _NSUserDefaults()						[NSUserDefaults standardUserDefaults]
#define _NSAppleEventManager()					[NSAppleEventManager sharedAppleEventManager]
#define _NSNotificationCenter()					[NSNotificationCenter defaultCenter]
#define _NSUserDefaultsController()				[NSUserDefaultsController sharedUserDefaultsController]
#define _NSWorkspaceNotificationCenter()		[_NSWorkspace() notificationCenter]
#define _NSDistributedNotificationCenter()		[NSDistributedNotificationCenter defaultCenter]

/* Miscellaneous functions to handle small tasks */
#define CFItemRefToID(s)					(id)s

#define PointerIsEmpty(s)					(s == NULL || s == nil)
#define PointerIsNotEmpty(s)				BOOLReverseValue(PointerIsEmpty(s))

#define BOOLReverseValue(b)					((b == YES) ? NO : YES)
#define BOOLValueFromObject(b)				BOOLReverseValue(PointerIsEmpty(b))

#define TEXTUAL_EXTERN                      __attribute__((visibility("default")))

/* Item types */
typedef unsigned long long TXFSLongInt; // filesizes

/* Number Handling */
#define NSNumberWithBOOL(b)					[NSNumber numberWithBool:b]
#define NSNumberWithInteger(i)				[NSNumber numberWithInteger:i]
#define NSNumberWithLongLong(l)				[NSNumber numberWithLongLong:l]
#define NSNumberWithDouble(d)				[NSNumber numberWithDouble:d]