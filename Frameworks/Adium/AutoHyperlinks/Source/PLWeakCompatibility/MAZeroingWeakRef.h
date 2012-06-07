//
//  MAZeroingWeakRef.h
//  ZeroingWeakRef
//
//  Created by Michael Ash on 7/5/10.
//

#import <Foundation/Foundation.h>


@interface MAZeroingWeakRef : NSObject
{
    id _target;
    BOOL _nativeZWR;
#if NS_BLOCKS_AVAILABLE
    void (^_cleanupBlock)(id target);
#endif
}

+ (BOOL)canRefCoreFoundationObjects;

+ (id)refWithTarget: (id)target;

- (id)initWithTarget: (id)target;

#if NS_BLOCKS_AVAILABLE
// ON 10.7:
// cleanup block runs while the target's memory is still
// allocated but after all dealloc methods have run
// (it runs at associated object cleanup time)
// you can use the target's pointer value but don't
// manipulate its contents!

// ON 10.6 AND BELOW:
// cleanup block runs while the global ZWR lock is held
// so make it short and sweet!
// use GCD or something to schedule execution later
// if you need to do something that may take a while
//
// it is unsafe to call -target on the weak ref from
// inside the cleanup block, which is why the target
// is passed in as a parameter
// note that you must not resurrect the target at this point!
- (void)setCleanupBlock: (void (^)(id target))block;
#endif

- (id)target;

@end

#ifndef __has_feature
#define __has_feature(feature) 0
#endif

#define MAWeakVar(var)            __weak_ ## var

#if __has_feature(objc_arc_weak)

#define MAWeakDeclare(var)        __weak __typeof__((var)) MAWeakVar(var) = var
#define MAWeakImport(var)         __typeof__((MAWeakVar(var))) var = MAWeakVar(var)
#define MAWeakImportReturn(var)   MAWeakImport(var); do { if(var == nil) return; } while(NO)

#else

#define MAWeakDeclare(var)        __typeof__((var)) MAWeakVar(var) = (id)[MAZeroingWeakRef refWithTarget:var]
#define MAWeakImport(var)         __typeof__((MAWeakVar(var))) var = [(MAZeroingWeakRef *)MAWeakVar(var) target]
#define MAWeakImportReturn(var)   MAWeakImport(var); do { if(var == nil) return; } while(NO)

#endif

#define MAWeakSelfDeclare()       MAWeakDeclare(self)
#define MAWeakSelfImport()        MAWeakImport(self)
#define MAWeakSelfImportReturn()  MAWeakImportReturn(self)
