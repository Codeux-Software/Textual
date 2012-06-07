//
//  PLWeakCompatibilityStubs.h
//  PLWeakCompatibility
//
//  Created by Michael Ash on 3/28/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

// A typedef used in place of id to prevent ARC from getting its hands dirty with
// our object pointers. Even with __unsafe_unretained, ARC likes to do things like
// retain and release intermediate values, which gets us into serious trouble.
typedef void *PLObjectPtr;


// These are prototypes of the various runtime functions the compiler calls to handle
// __weak variables. If you import this header and these prototypes interfere with
// the official ones (due to using PLObjectPtr instead of id), simply do
// #define EXCLUDE_STUB_PROTOTYPES 1 immediately before the import statement to
// exclude these.
#if !EXCLUDE_STUB_PROTOTYPES
PLObjectPtr objc_loadWeakRetained(PLObjectPtr *location);
PLObjectPtr objc_initWeak(PLObjectPtr *addr, PLObjectPtr val);
void objc_destroyWeak(PLObjectPtr *addr);
void objc_copyWeak(PLObjectPtr *to, PLObjectPtr *from);
void objc_moveWeak(PLObjectPtr *to, PLObjectPtr *from);
PLObjectPtr objc_loadWeak(PLObjectPtr *location);
PLObjectPtr objc_storeWeak(PLObjectPtr *location, PLObjectPtr obj);
#endif

// Enable or disable the use of MAZeroingWeakRef. If enabled is YES, then
// MAZeroingWeakRef is used to implement the __weak functionality if present.
// If MAZWR is not present in your process, then it falls back to its simpler
// internal implementation. MAZWR use is enabled by default. Note that
// changing this value after weak references have been manipulated is
// extremely forbidden and will cause no end to havoc.
void PLWeakCompatibilitySetMAZWREnabled(BOOL enabled);

// Check whether MAZeroingWeakRef is in use. Returns YES if and only if
// MAZeroingWeakRef is present in the process and its use is not disabled
// with the above function. Returns NO if MAZWR is not present or its
// use has been explicitly disabled.
BOOL PLWeakCompatibilityHasMAZWR(void);

// Enable or disable the use of native fallthroughs to built-in runtime functions
// when present. When enabled, if the necessary weak reference functions are
// present in the Objective-C runtime, they are called instead of the third-party
// weak reference implementation. When disabled, the third-party implementation
// is always used. This is enabled by default, and should not be disabled except
// for testing purposes. Do not change this value after weak references have been
// manipulated, or you will severely regret it.
void PLWeakCompatibilitySetFallthroughEnabled(BOOL enabled);
