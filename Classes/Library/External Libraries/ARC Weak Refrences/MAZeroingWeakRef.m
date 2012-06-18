//
//  MAZeroingWeakRef.m
//  ZeroingWeakRef
//
//  Created by Michael Ash on 7/5/10.
//

#import "MAZeroingWeakRef.h"

#import "MAZeroingWeakRefNativeZWRNotAllowedTable.h"

#import <CommonCrypto/CommonDigest.h>

#import <dlfcn.h>
#import <libkern/OSAtomic.h>
#import <objc/runtime.h>
#import <mach/mach.h>
#import <mach/port.h>
#import <pthread.h>


/*
 The COREFOUNDATION_HACK_LEVEL macro allows you to control how much horrible CF
 hackery is enabled. The following levels are defined:
 
 3 - Completely insane hackery allows weak references to CF objects, deallocates
 them asynchronously in another thread to eliminate resurrection-related race
 condition and crash.
 
 2 - Full hackery allows weak references to CF objects by doing horrible
 things with the private CF class table. Extremely small risk of resurrection-
 related race condition leading to a crash.
 
 1 - Mild hackery allows foolproof identification of CF objects and will assert
 if trying to make a ZWR to one.
 
 0 - No hackery, checks for an "NSCF" prefix in the class name to identify CF
 objects and will assert if trying to make a ZWR to one
 */
#ifndef COREFOUNDATION_HACK_LEVEL
#define COREFOUNDATION_HACK_LEVEL 0
#endif

/*
 The KVO_HACK_LEVEL macro allows similar control over the amount of KVO hackery.
 
 1 - Use the private _isKVOA method to check for a KVO dynamic subclass.
 
 0 - No hackery, uses the KVO overridden -class to check.
 */
#ifndef KVO_HACK_LEVEL
#define KVO_HACK_LEVEL 1
#endif

/*
 The USE_BLOCKS_BASED_LOCKING macro allows control on the code structure used
 during lock checking. You want to disable blocks if you want your app to work
 on iOS 3.x devices. iOS 4.x and above can use blocks.

 1 - Use blocks for lock checks.

 0 - Don't use blocks for lock checks.
 */
#ifndef USE_BLOCKS_BASED_LOCKING
#define USE_BLOCKS_BASED_LOCKING 1
#endif

#if KVO_HACK_LEVEL >= 1
@interface NSObject (KVOPrivateMethod)

- (BOOL)_isKVOA;

@end
#endif


@interface MAZeroingWeakRef ()

- (void)_zeroTarget;
- (void)_executeCleanupBlockWithTarget: (id)target;

@end


static id (*objc_loadWeak_fptr)(id *location);
static id (*objc_storeWeak_fptr)(id *location, id obj);

@interface _MAZeroingWeakRefCleanupHelper : NSObject
{
    MAZeroingWeakRef *_ref;
    id _target;
}

- (id)initWithRef: (MAZeroingWeakRef *)ref target: (id)target;

@end

@implementation _MAZeroingWeakRefCleanupHelper

- (id)initWithRef: (MAZeroingWeakRef *)ref target: (id)target
{
    if((self = [self init]))
    {
        objc_storeWeak_fptr(&_ref, ref);
        _target = target;
    }
    return self;
}

- (void)dealloc
{
    MAZeroingWeakRef *ref = objc_loadWeak_fptr(&_ref);
    [ref _executeCleanupBlockWithTarget: _target];
    objc_storeWeak_fptr(&_ref, nil);
    
    [super dealloc];
}

@end


@implementation MAZeroingWeakRef

#if COREFOUNDATION_HACK_LEVEL >= 2

typedef struct __CFRuntimeClass {	// Version 0 struct
    CFIndex version;
    const char *className;
    void (*init)(CFTypeRef cf);
    CFTypeRef (*copy)(CFAllocatorRef allocator, CFTypeRef cf);
    void (*finalize)(CFTypeRef cf);
    Boolean (*equal)(CFTypeRef cf1, CFTypeRef cf2);
    CFHashCode (*hash)(CFTypeRef cf);
    CFStringRef (*copyFormattingDesc)(CFTypeRef cf, CFDictionaryRef formatOptions);	// str with retain
    CFStringRef (*copyDebugDesc)(CFTypeRef cf);	// str with retain
    void (*reclaim)(CFTypeRef cf);
} CFRuntimeClass;

extern CFRuntimeClass * _CFRuntimeGetClassWithTypeID(CFTypeID typeID);

typedef void (*CFFinalizeFptr)(CFTypeRef);
static CFFinalizeFptr *gCFOriginalFinalizes;
static size_t gCFOriginalFinalizesSize;

#endif

#if COREFOUNDATION_HACK_LEVEL >= 1

extern Class *__CFRuntimeObjCClassTable;

#endif

static pthread_mutex_t gMutex;

static CFMutableDictionaryRef gObjectWeakRefsMap; // maps (non-retained) objects to CFMutableSetRefs containing weak refs

static NSMutableSet *gCustomSubclasses;
static NSMutableDictionary *gCustomSubclassMap; // maps regular classes to their custom subclasses

#if COREFOUNDATION_HACK_LEVEL >= 3
static CFMutableSetRef gCFWeakTargets;
static NSOperationQueue *gCFDelayedDestructionQueue;
#endif

+ (void)initialize
{
    if(self == [MAZeroingWeakRef class])
    {
        pthread_mutexattr_t mutexattr;
        pthread_mutexattr_init(&mutexattr);
        pthread_mutexattr_settype(&mutexattr, PTHREAD_MUTEX_RECURSIVE);
        pthread_mutex_init(&gMutex, &mutexattr);
        pthread_mutexattr_destroy(&mutexattr);
        
        gObjectWeakRefsMap = CFDictionaryCreateMutable(NULL, 0, NULL, &kCFTypeDictionaryValueCallBacks);
        gCustomSubclasses = [[NSMutableSet alloc] init];
        gCustomSubclassMap = [[NSMutableDictionary alloc] init];
        
        // see if the 10.7 ZWR runtime functions are available
        // nothing special about objc_allocateClassPair, it just
        // seems like a reasonable and safe choice for finding
        // the runtime functions
        Dl_info info;
        int success = dladdr(objc_allocateClassPair, &info);
        if(success)
        {
            // note: we leak the handle because it's inconsequential
            // and technically, the fptrs would be invalid after a dlclose
            void *handle = dlopen(info.dli_fname, RTLD_LAZY | RTLD_GLOBAL);
            if(handle)
            {
                objc_loadWeak_fptr = dlsym(handle, "objc_loadWeak");
                objc_storeWeak_fptr = dlsym(handle, "objc_storeWeak");
                
                // if either one failed, make sure both are zeroed out
                // this is probably unnecessary, but good paranoia
                if(!objc_loadWeak_fptr || !objc_storeWeak_fptr)
                {
                    objc_loadWeak_fptr = NULL;
                    objc_storeWeak_fptr = NULL;
                }
            }
        }
        
#if COREFOUNDATION_HACK_LEVEL >= 3
        gCFWeakTargets = CFSetCreateMutable(NULL, 0, NULL);
        gCFDelayedDestructionQueue = [[NSOperationQueue alloc] init];
#endif
    }
}

#if USE_BLOCKS_BASED_LOCKING
#define BLOCK_QUALIFIER __block
static void WhileLocked(void (^block)(void))
{
    pthread_mutex_lock(&gMutex);
    block();
    pthread_mutex_unlock(&gMutex);
}
#define WhileLocked(block) WhileLocked(^block)
#else
#define BLOCK_QUALIFIER
#define WhileLocked(block) do { \
        pthread_mutex_lock(&gMutex); \
        block \
        pthread_mutex_unlock(&gMutex); \
    } while(0)
#endif

static void AddWeakRefToObject(id obj, MAZeroingWeakRef *ref)
{
    CFMutableSetRef set = (void *)CFDictionaryGetValue(gObjectWeakRefsMap, obj);
    if(!set)
    {
        set = CFSetCreateMutable(NULL, 0, NULL);
        CFDictionarySetValue(gObjectWeakRefsMap, obj, set);
        CFRelease(set);
    }
    CFSetAddValue(set, ref);
}

static void RemoveWeakRefFromObject(id obj, MAZeroingWeakRef *ref)
{
    CFMutableSetRef set = (void *)CFDictionaryGetValue(gObjectWeakRefsMap, obj);
    CFSetRemoveValue(set, ref);
}

static void ClearWeakRefsForObject(id obj)
{
    CFMutableSetRef set = (void *)CFDictionaryGetValue(gObjectWeakRefsMap, obj);
    if(set)
    {
        NSSet *setCopy = [[NSSet alloc] initWithSet: (NSSet *)set];
        [setCopy makeObjectsPerformSelector: @selector(_zeroTarget)];
        [setCopy makeObjectsPerformSelector: @selector(_executeCleanupBlockWithTarget:) withObject: obj];
        [setCopy release];
        CFDictionaryRemoveValue(gObjectWeakRefsMap, obj);
    }
}

static Class GetCustomSubclass(id obj)
{
    Class class = object_getClass(obj);
    while(class && ![gCustomSubclasses containsObject: class])
        class = class_getSuperclass(class);
    return class;
}

static Class GetRealSuperclass(id obj)
{
    Class class = GetCustomSubclass(obj);
    NSCAssert1(class, @"Coudn't find ZeroingWeakRef subclass in hierarchy starting from %@, should never happen", object_getClass(obj));
    return class_getSuperclass(class);
}

static void CustomSubclassRelease(id self, SEL _cmd)
{
    Class superclass = GetRealSuperclass(self);
    IMP superRelease = class_getMethodImplementation(superclass, @selector(release));
    WhileLocked({
        ((void (*)(id, SEL))superRelease)(self, _cmd);
    });
}

static void CustomSubclassDealloc(id self, SEL _cmd)
{
    ClearWeakRefsForObject(self);
    Class superclass = GetRealSuperclass(self);
    IMP superDealloc = class_getMethodImplementation(superclass, @selector(dealloc));
    ((void (*)(id, SEL))superDealloc)(self, _cmd);
}

static Class CustomSubclassClassForCoder(id self, SEL _cmd)
{
    Class class = GetCustomSubclass(self);
    Class superclass = class_getSuperclass(class);
    IMP superClassForCoder = class_getMethodImplementation(superclass, @selector(classForCoder));
    Class classForCoder = ((id (*)(id, SEL))superClassForCoder)(self, _cmd);
    if(classForCoder == class)
        classForCoder = superclass;
    return classForCoder;
}

static void KVOSubclassRelease(id self, SEL _cmd)
{
    IMP originalRelease = class_getMethodImplementation(object_getClass(self), @selector(MAZeroingWeakRef_KVO_original_release));
    WhileLocked({
        ((void (*)(id, SEL))originalRelease)(self, _cmd);
    });
}

static void KVOSubclassDealloc(id self, SEL _cmd)
{
    ClearWeakRefsForObject(self);
    IMP originalDealloc = class_getMethodImplementation(object_getClass(self), @selector(MAZeroingWeakRef_KVO_original_dealloc));
    ((void (*)(id, SEL))originalDealloc)(self, _cmd);
}

#if COREFOUNDATION_HACK_LEVEL >= 3

static void CallCFReleaseLater(CFTypeRef cf)
{
    mach_port_t thread = mach_thread_self(); // must "release" this
    
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    SEL sel = @selector(releaseLater:fromThread:);
    NSInvocation *inv = [NSInvocation invocationWithMethodSignature: [MAZeroingWeakRef methodSignatureForSelector: sel]];
    [inv setTarget: [MAZeroingWeakRef class]];
    [inv setSelector: sel];
    [inv setArgument: &cf atIndex: 2];
    [inv setArgument: &thread atIndex: 3];
    
    NSInvocationOperation *op = [[NSInvocationOperation alloc] initWithInvocation: inv];
    [gCFDelayedDestructionQueue addOperation: op];
    [op release];
    [pool release];
}

static const void *kPCThreadExited = &kPCThreadExited;
static const void *kPCError = NULL;

static const void *GetPC(mach_port_t thread)
{
#if defined(__x86_64__)
    x86_thread_state64_t state;
    unsigned int count = x86_THREAD_STATE64_COUNT;
    thread_state_flavor_t flavor = x86_THREAD_STATE64;
#define PC_REGISTER __rip
#elif defined(__i386__)
    i386_thread_state_t state;
    unsigned int count = i386_THREAD_STATE_COUNT;
    thread_state_flavor_t flavor = i386_THREAD_STATE;
#define PC_REGISTER __eip
#elif defined(__arm__)
    arm_thread_state_t state;
    unsigned int count = ARM_THREAD_STATE_COUNT;
    thread_state_flavor_t flavor = ARM_THREAD_STATE;
#define PC_REGISTER __pc
#elif defined(__ppc__)
    ppc_thread_state_t state;
    unsigned int count = PPC_THREAD_STATE_COUNT;
    thread_state_flavor_t flavor = PPC_THREAD_STATE;
#define PC_REGISTER __srr0
#elif defined(__ppc64__)
    ppc_thread_state64_t state;
    unsigned int count = PPC_THREAD_STATE64_COUNT;
    thread_state_flavor_t flavor = PPC_THREAD_STATE64;
#define PC_REGISTER __srr0
#else
#error don't know how to get PC for the current architecture!
#endif
    
    kern_return_t ret = thread_get_state(thread, flavor, (thread_state_t)&state, &count);
    if(ret == KERN_SUCCESS)
        return (void *)state.PC_REGISTER;
    else if(ret == KERN_INVALID_ARGUMENT)
        return kPCThreadExited;
    else
        return kPCError;
}

static void CustomCFFinalize(CFTypeRef cf)
{
    WhileLocked({
        if(CFSetContainsValue(gCFWeakTargets, cf))
        {
            if(CFGetRetainCount(cf) == 1)
            {
                ClearWeakRefsForObject((id)cf);
                CFSetRemoveValue(gCFWeakTargets, cf);
                CFRetain(cf);
                CallCFReleaseLater(cf);
            }
        }
        else
        {
            void (*fptr)(CFTypeRef) = gCFOriginalFinalizes[CFGetTypeID(cf)];
            if(fptr)
                fptr(cf);
        }
    });
}

#elif COREFOUNDATION_HACK_LEVEL >= 2

static void CustomCFFinalize(CFTypeRef cf)
{
    WhileLocked({
        if(CFGetRetainCount(cf) == 1)
        {
            ClearWeakRefsForObject((id)cf);
            void (*fptr)(CFTypeRef) = gCFOriginalFinalizes[CFGetTypeID(cf)];
            if(fptr)
                fptr(cf);
        }
    });
}
#endif

static BOOL IsTollFreeBridged(Class class, id obj)
{
#if COREFOUNDATION_HACK_LEVEL >= 1
    CFTypeID typeID = CFGetTypeID(obj);
    Class tfbClass = __CFRuntimeObjCClassTable[typeID];
    return class == tfbClass;
#else
    NSString *className = NSStringFromClass(class);
    return [className hasPrefix:@"NSCF"] || [className hasPrefix:@"__NSCF"];
#endif
}

static BOOL IsConstantObject(id obj)
{
  unsigned int retainCount = [obj retainCount];
  return retainCount == UINT_MAX || retainCount == INT_MAX;
}

#if COREFOUNDATION_HACK_LEVEL >= 3
void _CFRelease(CFTypeRef cf);

+ (void)releaseLater: (CFTypeRef)cf fromThread: (mach_port_t)thread
{
    BOOL retry = YES;
    
    while(retry)
    {
        BLOCK_QUALIFIER const void *pc;
        // ensure that the PC is outside our inner code when fetching it,
        // so we don't have to check for all the nested calls
        WhileLocked({
            pc = GetPC(thread);
        });
        
        if(pc != kPCError)
        {
            if(pc == kPCThreadExited || pc < (void *)CustomCFFinalize || pc > (void *)IsTollFreeBridged)
            {
                Dl_info info;
                int success = dladdr(pc, &info);
                if(success)
                {
                    if(info.dli_saddr != _CFRelease)
                    {
                        retry = NO; // success!
                        CFRelease(cf);
                        mach_port_mod_refs(mach_task_self(), thread, MACH_PORT_RIGHT_SEND, -1 ); // "release"
                    }
                }
            }
        }
    }
}
#endif

static BOOL IsKVOSubclass(id obj)
{
#if KVO_HACK_LEVEL >= 1
    return [obj respondsToSelector: @selector(_isKVOA)] && [obj _isKVOA];
#else
    return [obj class] == class_getSuperclass(object_getClass(obj));
#endif
}

// The native ZWR capability table is conceptually a set of SHA1 hashes.
// Hashes are used instead of class names because the table is large and
// contains a lot of private classes. Embedding private class names in
// the binary is likely to cause problems with app review. Manually
// removing all private classes from the table is a lot of work. Using
// hashes allows for reasonably quick checks and no private API names.
// It's implemented as a tree of tables, where each individual table
// maps to a single byte. The top level of the tree is a 256-entry table.
// Table entries are a NULL pointer for leading bytes which aren't present
// at all. Other table entries can either contain a pointer to another
// table (in which case the process continues recursively), or they can
// contain a pointer to a single hash. In this second case, this indicates
// that this hash is the only one present in the table with that prefix
// and so a simple comparison can be used to check for membership at
// that point.
static BOOL HashPresentInTable(unsigned char *hash, int length, struct _NativeZWRTableEntry *table)
{
    while(length)
    {
        struct _NativeZWRTableEntry entry = table[hash[0]];
        if(entry.ptr == NULL)
        {
            return NO;
        }
        else if(!entry.isTable)
        {
            return memcmp(entry.ptr, hash + 1, length - 1) == 0;
        }
        else
        {
            hash++;
            length--;
            table = entry.ptr;
        }
    }
    return NO;
}

static BOOL CanNativeZWRClass(Class c)
{
    if(!c)
        return YES;
    
    const char *name = class_getName(c);
    unsigned char hash[CC_SHA1_DIGEST_LENGTH];
    CC_SHA1(name, strlen(name), hash);
    
    if(HashPresentInTable(hash, CC_SHA1_DIGEST_LENGTH, _MAZeroingWeakRefClassNativeWeakReferenceNotAllowedTable))
        return NO;
    else
        return CanNativeZWRClass(class_getSuperclass(c));
}

static BOOL CanNativeZWR(id obj)
{
    return CanNativeZWRClass(object_getClass(obj));
}

static Class CreatePlainCustomSubclass(Class class)
{
    NSString *newName = [NSString stringWithFormat: @"%s_MAZeroingWeakRefSubclass", class_getName(class)];
    const char *newNameC = [newName UTF8String];
    
    Class subclass = objc_allocateClassPair(class, newNameC, 0);
    
    Method release = class_getInstanceMethod(class, @selector(release));
    Method dealloc = class_getInstanceMethod(class, @selector(dealloc));
    Method classForCoder = class_getInstanceMethod(class, @selector(classForCoder));
    class_addMethod(subclass, @selector(release), (IMP)CustomSubclassRelease, method_getTypeEncoding(release));
    class_addMethod(subclass, @selector(dealloc), (IMP)CustomSubclassDealloc, method_getTypeEncoding(dealloc));
    class_addMethod(subclass, @selector(classForCoder), (IMP)CustomSubclassClassForCoder, method_getTypeEncoding(classForCoder));
    
    objc_registerClassPair(subclass);
    
    return subclass;
}

static void PatchKVOSubclass(Class class)
{
    NSLog(@"Patching KVO class %s", class_getName(class));
    Method release = class_getInstanceMethod(class, @selector(release));
    Method dealloc = class_getInstanceMethod(class, @selector(dealloc));
    
    class_addMethod(class, @selector(MAZeroingWeakRef_KVO_original_release), method_getImplementation(release), method_getTypeEncoding(release));
    class_addMethod(class, @selector(MAZeroingWeakRef_KVO_original_dealloc), method_getImplementation(dealloc), method_getTypeEncoding(dealloc));
    
    class_replaceMethod(class, @selector(release), (IMP)KVOSubclassRelease, method_getTypeEncoding(release));
    class_replaceMethod(class, @selector(dealloc), (IMP)KVOSubclassDealloc, method_getTypeEncoding(dealloc));
}

static void RegisterCustomSubclass(Class subclass, Class superclass)
{
    [gCustomSubclassMap setObject: subclass forKey: superclass];
    [gCustomSubclasses addObject: subclass];
}

static Class CreateCustomSubclass(Class class, id obj)
{
    if(IsTollFreeBridged(class, obj))
    {
#if COREFOUNDATION_HACK_LEVEL >= 2
        CFTypeID typeID = CFGetTypeID(obj);
        CFRuntimeClass *cfclass = _CFRuntimeGetClassWithTypeID(typeID);
        
        if(typeID >= gCFOriginalFinalizesSize)
        {
            gCFOriginalFinalizesSize = typeID + 1;
            gCFOriginalFinalizes = realloc(gCFOriginalFinalizes, gCFOriginalFinalizesSize * sizeof(*gCFOriginalFinalizes));
        }
        
        do {
            gCFOriginalFinalizes[typeID] = cfclass->finalize;
        } while(!OSAtomicCompareAndSwapPtrBarrier(gCFOriginalFinalizes[typeID], CustomCFFinalize, (void *)&cfclass->finalize));
#else
        NSCAssert2(0, @"Cannot create zeroing weak reference to object of type %@ with COREFOUNDATION_HACK_LEVEL set to %d", class, COREFOUNDATION_HACK_LEVEL);          
#endif
        return class;
    }
    else if(IsKVOSubclass(obj))
    {
        PatchKVOSubclass(class);
        return class;
    }
    else
    {
        return CreatePlainCustomSubclass(class);
    }
}

static void EnsureCustomSubclass(id obj)
{
    if(!GetCustomSubclass(obj) && !IsConstantObject(obj))
    {
        Class class = object_getClass(obj);
        Class subclass = [gCustomSubclassMap objectForKey: class];
        if(!subclass)
        {
            subclass = CreateCustomSubclass(class, obj);
            RegisterCustomSubclass(subclass, class);
        }
        
        // only set the class if the current one is its superclass
        // otherwise it's possible that it returns something farther up in the hierarchy
        // and so there's no need to set it then
        if(class_getSuperclass(subclass) == class)
            object_setClass(obj, subclass);
    }
}

static void RegisterRef(MAZeroingWeakRef *ref, id target)
{
    WhileLocked({
        EnsureCustomSubclass(target);
        AddWeakRefToObject(target, ref);
#if COREFOUNDATION_HACK_LEVEL >= 3
        if(IsTollFreeBridged(object_getClass(target), target))
            CFSetAddValue(gCFWeakTargets, target);
#endif
    });
}

static void UnregisterRef(MAZeroingWeakRef *ref)
{
    WhileLocked({
        id target = ref->_target;
        
        if(target)
            RemoveWeakRefFromObject(target, ref);
    });
}

+ (BOOL)canRefCoreFoundationObjects
{
    return COREFOUNDATION_HACK_LEVEL >= 2 || objc_storeWeak_fptr;
}

+ (id)refWithTarget: (id)target
{
    return [[[self alloc] initWithTarget: target] autorelease];
}

- (id)initWithTarget: (id)target
{
    if((self = [self init]))
    {
        if(objc_storeWeak_fptr && CanNativeZWR(target))
        {
            objc_storeWeak_fptr(&_target, target);
            _nativeZWR = YES;
        }
        else
        {
            _target = target;
            RegisterRef(self, target);
        }
    }
    return self;
}

- (void)dealloc
{
    if(objc_storeWeak_fptr && _nativeZWR)
        objc_storeWeak_fptr(&_target, nil);
    else
        UnregisterRef(self);
    
#if NS_BLOCKS_AVAILABLE
    [_cleanupBlock release];
#endif
    [super dealloc];
}

- (NSString *)description
{
    return [NSString stringWithFormat: @"<%@: %p -> %@>", [self class], self, [self target]];
}

#if NS_BLOCKS_AVAILABLE
- (void)setCleanupBlock: (void (^)(id target))block
{
    block = [block copy];
    [_cleanupBlock release];
    _cleanupBlock = block;
    
    if(objc_loadWeak_fptr && _nativeZWR)
    {
        // wrap a pool around this code, otherwise it artificially extends
        // the lifetime of the target object
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        id target = [self target];
        if(target != nil) @synchronized(target)
        {
            static void *associatedKey = &associatedKey;
            NSMutableSet *cleanupHelpers = objc_getAssociatedObject(target, associatedKey);
            
            if(cleanupHelpers == nil)
            {
                cleanupHelpers = [NSMutableSet set];
                objc_setAssociatedObject(target, associatedKey, cleanupHelpers, OBJC_ASSOCIATION_RETAIN);
            }
            
            _MAZeroingWeakRefCleanupHelper *helper = [[_MAZeroingWeakRefCleanupHelper alloc] initWithRef: self target: target];
            [cleanupHelpers addObject:helper];
            
            [helper release];
        }
        
        [pool release];
    }
}
#endif

- (id)target
{
    if(objc_loadWeak_fptr && _nativeZWR)
    {
        return objc_loadWeak_fptr(&_target);
    }
    else
    {
        BLOCK_QUALIFIER id ret;
        WhileLocked({
            ret = [_target retain];
        });
        return [ret autorelease];
    }
}

- (void)_zeroTarget
{
    _target = nil;
}

- (void)_executeCleanupBlockWithTarget: (id)target
{
#if NS_BLOCKS_AVAILABLE
    if(_cleanupBlock)
    {
        _cleanupBlock(target);
        [_cleanupBlock release];
        _cleanupBlock = nil;
    }
#endif
}

@end
