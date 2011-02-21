#!/bin/sh

#DEBUG=1;

DEFAULT_DEBUG=1;
DEFAULT_LEAK_CHECK=0;
DEFAULT_TIMING=0;
DEFAULT_MULTITHREADING=0;
DEFAULT_SLEEP_WHEN_FINISHED=0;

export DEBUG=${DEBUG:-$DEFAULT_DEBUG};
export LEAK_CHECK=${LEAK_CHECK:-$DEFAULT_LEAK_CHECK};
export TIMING=${TIMING:-$DEFAULT_TIMING};
export MULTITHREADING=${MULTITHREADING:-$DEFAULT_MULTITHREADING};
export SLEEP_WHEN_FINISHED=${SLEEP_WHEN_FINISHED:-$DEFAULT_SLEEP_WHEN_FINISHED};

echo "DEBUG is set to $DEBUG";
echo "LEAK_CHECK is set to $LEAK_CHECK";
echo "TIMING is set to $TIMING";
echo "MULTITHREADING is set to $MULTITHREADING";
echo "SLEEP_WHEN_FINISHED is set to ${SLEEP_WHEN_FINISHED}";

#export DYLD_INSERT_LIBRARIES=/usr/lib/libMallocDebug.A.dylib

if (($DEBUG > 0)); then
export OBJC_PRINT_GC=YES;
echo "OBJC_PRINT_GC=${OBJC_PRINT_GC}";
fi;

########################
#
#   malloc library
#
########################

# Create/append messages to the given file path <f> instead
# of writing to the standard error.
#
#export MallocLogFile="file"

# Add guard pages before and after large allocations
#
if (($DEBUG > 0)); then
export MallocGuardEdges=1;
echo "MallocGuardEdges=MallocGuardEdges";
fi;

# If set, do not add a guard page before large
# blocks, even if the MallocGuardEdges environment
# variable is set.
#
#export MallocDoNotProtectPrelude=1

# If set, do not add a guard page after large
# blocks, even if the MallocGuardEdges environment
# variable is set.
#
#export MallocDoNotProtectPostlude=1

# Fill newly allocated memory with 0xAA (10.4)
#
if (($DEBUG > 0)); then
export MallocPreScribble=1;
echo "MallocPreScribble=$MallocPreScribble";
fi;

# Fill deallocated memory with 0x55
#
if (($DEBUG > 0)); then
export MallocScribble=1;
echo "MallocScribble=$MallocScribble";
fi;

# If set, record all stacks in a manner that is compatible
# with the `malloc_history` program.
#
#export MallocStackLoggingNoCompact=1
if (($DEBUG > 1)); then
export MallocStackLoggingNoCompact=1;
echo "MallocStackLoggingNoCompact=$MallocStackLoggingNoCompact";
fi;

if (($LEAK_CHECK > 0)); then
export MallocStackLogging=1;
echo "MallocStackLogging=$MallocStackLogging";
fi;

# If set, record all stacks, so that tools like `leaks` can be used.
#
#if (($DEBUG == 1 && $LEAK_CHECK < 1)); then
#export MallocStackLogging=1;
#echo "MallocStackLogging=$MallocStackLogging";
#fi;


# If set to a non-zero value, causes abort(3)
# to be called if the pointer passed to
# free(3) was previously freed, or is otherwise illegal.
#
#export MallocBadFreeAbort=1

########################
#
#   Core Services
#
########################

# Core Services includes a number of routines (for example,
# Debugger, DebugStr, and SysBreak) that enter the debugger
# with a message. If you set the USERBREAK environment
# variable to 1, these routines will send a SIGINT signal
# to the current process, which causes you to break into GDB.
#
#export USERBREAK=1


########################
#
#   Core Foundation
#
########################

# The Core Foundation debug library supports an environment
# variable called CFZombieLevel. It interprets this variable
# as an integer containing a set of flag bits
#
# 0      scribble deallocated CF memory
# 1      when scribbling deallocated CF memory, don't scribble object header (CFRuntimeBase)
# 4      never free memory used to hold CF objects
# 7      if set, scribble deallocations using bits 8..15, otherwise use 0xFC
# 8..15  if bit 7 is set, scribble deallocations using this value
# 16     scribble allocated CF memory
# 23     if set, scribble allocations using bits 24..31, otherwise use 0xCF
# 24..31 if bit 16 is set, scribble allocations using this value
#
# 65537 = 0x00010001 = (1<<16) | (1<<0)
# 65539 = 0x00010003 = (1<<16) | (1<<1) | (1<<0)
# 65555 = 0x00010013 = (1<<16) | (1<<4) | (1<<1) | (1<<0)
#
if (($DEBUG > 0)); then
export CFZombieLevel=65537;
echo "CFZombieLevel=$CFZombieLevel";
fi;

########################
#
#     Foundation
#
########################

# If set to YES, deallocated objects are 'zombified';
# this allows you to quickly debug problems where you send a
# message to an object that has already been freed
#
if (($DEBUG > 0)); then
export NSZombieEnabled=YES;
echo "NSZombieEnabled=$NSZombieEnabled";
fi;

# If set to YES, the memory for 'zombified' objects is actually freed
#
if (($DEBUG > 0)); then
export NSDeallocateZombies=YES;
echo "NSDeallocateZombies=$NSDeallocateZombies";
fi;

# If set to YES, autorelease pools will print a message if
# they try to release an object that has already been freed
#
if (($DEBUG > 0)); then
export NSAutoreleaseFreedObjectCheckEnabled=YES;
echo "NSAutoreleaseFreedObjectCheckEnabled=$NSAutoreleaseFreedObjectCheckEnabled";
fi;


if (($DEBUG > 0)); then
export NSDebugEnabled=YES;
echo "NSDebugEnabled=$NSDebugEnabled";
fi;

# If set to NO, autorelease pools do not release objects in the pool when the pool is released
#
#export NSEnableAutoreleasePool=NO

# If set to X, autorelease pools will print a message if more than X objects accumulate in the poo
#
#export NSAutoreleaseHighWaterMark=#

# If set to Y, a message is logged for every Y objects that accumulate in the pool beyond the high-water mark (X)
#
#export NSAutoreleaseHighWaterResolution=#

# If set to YES, the process will hang, rather than quit, when an uncaught exception is raised
#
#export NSHangOnUncaughtException=YES

# If you set the NSObjCMessageLoggingEnabled environment variable to "YES",
# the Objective-C runtime will log all dispatched Objective-C messages
# to a file named /tmp/msgSends-<pid>.
#
#export NSObjCMessageLoggingEnabled=YES

# If you set the NSPrintDynamicClassLoads environment variable to "YES", 
# Foundation will log a message whenever it loads a class or category
# dynamically (that is, from a bundle).
#
#export NSPrintDynamicClassLoads=YES

# If you set the NSExceptionLoggingEnabled environment variable to "YES",
# Foundation will log all exception activity (NSException) to stderr.
# note: NSExceptionLogging is very chatty
#
#export NSExceptionLoggingEnabled=YES

# If you set the NSUnbufferedIO environment variable to "YES",
# Foundation will use unbuffered I/O for stdout (stderr is unbuffered by default).
#
#export NSUnbufferedIO=YES

# If you set the NSDOLoggingEnabled environment variable to "YES",
#  Foundation will enable logging for Distributed Objects
# (NSConnection, NSInvocation, NSDistantObject, and NSConcretePortCoder).
#
#export NSDOLoggingEnabled=YES

# You can enable logging for Foundation's scripting support
# using the NSScriptingDebugLogLevel preference.
#$ /Applications/TextEdit.app/Contents/MacOS/TextEdit -NSScriptingDebugLogLevel 1
#
#export NSScriptingDebugLogLevel=# ??


########################
#
#      AppKit
#
########################

# If you set the NSQuitAfterLaunch environment variable to 1,
# your application will quit as soon as it enters its event loop.
#
#export NSQuitAfterLaunch=1

# If you set the NSTraceEvents preference to YES,
# AppKit will log information about all events it processes
#
#export NSTraceEvents=YES

# If you set the NSShowAllViews preference to YES, AppKit will draw
# outlines around each of the views in a window
#
#export NSShowAllViews=YES

# You can control the duration of the flash by setting NSShowAllDrawing
# to a number, which is interpreted as the number of milliseconds to flash;
#
#export NSShowAllDrawing=#
#export NSShowAllDrawing=YES

# RGB floating point triplet
#
#export NSShowAllDrawingColor="0.0 0.0 0.0"
#export NSShowAllDrawingColor=CYCLE

# The NSDragManagerLogLevel preference is a number that
# controls how much logging AppKit does during drag and drop operations. 
# max is 6
#
#export NSDragManagerLogLevel=#

# The NSAccessibilityDebugLogLevel preference is a number
# that controls how much logging AppKit does during accessibility operations.
# max is 3
#
#export NSAccessibilityDebugLogLevel=#

########################
#
#     Threading
#
########################

# The Core Services threading APIs (MP threads and Thread Manager)
# support an environment variable, ThreadDebug, that enables a few
# debug messages and a number of internal consistency checks. This
# facility requires the Core Services debug library.
#
if (($DEBUG > 1)); then
export ThreadDebug=1;
echo "ThreadDebug=$ThreadDebug";
fi;


########################
#
#      Web Services
#
########################

# Web Services supports two helpful environment variables,
# WSDebug and WSDebugVerbose, which you can set to 1 to get
# limited and verbose debug logging, respectively. These variables
# are effective in the non-debug library, but include even more
# logging in the debug library.
#
#export WSDebug=1
#export WSDebugVerbose=1

########################
#
#  dyld Dynamic Linker
#
########################

#DYLD_PRINT_LIBRARIES
#DYLD_PRINT_LIBRARIES_POST_LAUNCH
#DYLD_PREBIND_DEBUG
#DYLD_PRINT_OPTS
#DYLD_PRINT_ENV
#DYLD_IGNORE_PREBINDING
#DYLD_PRINT_APIS
#DYLD_PRINT_BINDINGS
#DYLD_PRINT_INITIALIZERS
#DYLD_PRINT_SEGMENTS
#DYLD_PRINT_STATISTICS

########################
#
#  Objective C run time
#
########################

#OBJC_PRINT_IMAGES
#OBJC_PRINT_LOAD_METHODS
#OBJC_PRINT_CONNECTION
#OBJC_PRINT_RTP
#OBJC_PRINT_GC
#OBJC_PRINT_SHARING
#OBJC_PRINT_CXX_CTORS
#OBJC_USE_INTERNAL_ZONE
#OBJC_ALLOW_INTERPOSING
#OBJC_DEBUG_UNLOAD
#OBJC_DEBUG_FRAGILE_SUPERCLASSES
#OBJC_FORCE_GC
#OBJC_FORCE_NO_GC
#OBJC_CHECK_FINALIZERS
#if (($DEBUG > 0)) ; then
#export OBJC_FORCE_GC=YES
#echo "OBJC_FORCE_GC=${OBJC_FORCE_GC}"

#export OBJC_REPORT_GARBAGE=YES
#echo "OBJC_REPORT_GARBAGE=${OBJC_REPORT_GARBAGE}"

#export AUTO_LOG_COLLECT_DECISION=YES
#echo "OBJC_FORCE_GC=${AUTO_LOG_COLLECT_DECISION}"

#export OBJC_CHECK_FINALIZERS=YES
#echo "OBJC_FORCE_GC=${OBJC_CHECK_FINALIZERS}"

#fi

#OBJC_REPORT_GARBAGE
#OBJC_DISABLE_COLLECTION_INTERRUPT
#OBJC_EXPLICIT_ROOTS
#OBJC_COLLECTION_RATIO
#OBJC_COLLECTION_THRESHOLD
#OBJC_ISA_STOMP
#OBJC_RECORD_ALLOCATIONS

#AUTO_LOG_NOISY
#AUTO_LOG_ALL
#AUTO_LOG_COLLECTIONS
#AUTO_LOG_COLLECT_DECISION
#AUTO_LOG_GC_IMPL
#AUTO_LOG_REGIONS
#AUTO_LOG_UNUSUAL
#AUTO_LOG_WEAK
#AUTO_PARANOID_GENERATIONAL
#AUTO_DISABLE_GENERATIONAL
#OBJC_FINALIZATION_SAFE_CLASSES

########################
#
#    guard malloc
#
########################

# Enable guard malloc.  Execution is very, very slow.
#
if (($DEBUG > 2)); then
export DYLD_INSERT_LIBRARIES=/usr/lib/libgmalloc.dylib;
echo "DYLD_INSERT_LIBRARIES=$DYLD_INSERT_LIBRARIES";
if (($LEAK_CHECK > 0)); then
echo "WARNING: libgmalloc may interfere with leaks checking";
fi;
fi;


########################
#
#    Core dumps
#
########################

# Enable core dumps for this session
#
if (($DEBUG > 1)); then
ulimit -c unlimited;
echo "Core dumps are enabled";
fi;

########################
#
#    Debug libraries
#
########################

# Enable the _debug version of libraries which include additional assertions
# and debugging info.
#
if (($DEBUG > 0)); then
export DYLD_IMAGE_SUFFIX=_debug;
echo "DYLD_IMAGE_SUFFIX=$DYLD_IMAGE_SUFFIX";
fi;

#if (($LEAK_CHECK > 0)); then
#export DYLD_IMAGE_SUFFIX=_debug;
#echo "DYLD_IMAGE_SUFFIX=$DYLD_IMAGE_SUFFIX";
#echo "WARNING: _debug libraries may interfere with leaks checking"
#fi;



