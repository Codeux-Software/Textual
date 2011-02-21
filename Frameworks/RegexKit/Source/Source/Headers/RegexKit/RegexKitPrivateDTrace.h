//
//  RegexKitPrivateDTrace.h
//  RegexKit
//  http://regexkit.sourceforge.net/
//
//  PRIVATE HEADER -- NOT in RegexKit.framework/Headers
//

/*
 Copyright © 2007-2008, John Engelhart
 
 All rights reserved.
 
 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:
 
 * Redistributions of source code must retain the above copyright
 notice, this list of conditions and the following disclaimer.
 
 * Redistributions in binary form must reproduce the above copyright
 notice, this list of conditions and the following disclaimer in the
 documentation and/or other materials provided with the distribution.
 
 * Neither the name of the Zang Industries nor the names of its
 contributors may be used to endorse or promote products derived from
 this software without specific prior written permission.
 
 THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
 TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
 PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
 LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
 NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#ifdef __cplusplus
extern "C" {
#endif
  
#ifndef _REGEXKIT_REGEXKITPRIVATEDTRACE_H_
#define _REGEXKIT_REGEXKITPRIVATEDTRACE_H_ 1

#if defined(ENABLE_DTRACE_INSTRUMENTATION) && defined(__MACOSX_RUNTIME__)

// Used by Begin/End Match probes to squeeze additional information in to the probe firing.
typedef struct {
  void *object;
  const char *regex;
  int options;
} regexProbeObject;

#import "RegexKitProbes.h"

#define RK_PROBE_FIRE(probeName, ...) REGEXKIT_ ## probeName(__VA_ARGS__)
#define RK_PROBE_ENABLED(probeName)   RK_EXPECTED(REGEXKIT_ ## probeName ## _ENABLED(), 0)
#define RK_PROBE(probeName, ...)                        if(RK_PROBE_ENABLED(probeName)) { RK_PROBE_FIRE(probeName, __VA_ARGS__); }
#define RK_PROBE_CONDITIONAL(probeName, condition, ...) if(RK_EXPECTED(condition, 0))   { RK_PROBE_FIRE(probeName, __VA_ARGS__); }

#else // ENABLE_DTRACE_INSTRUMENTATION && __MACOSX_RUNTIME__ are not defined

#ifdef ENABLE_DTRACE_INSTRUMENTATION
#warning DTrace is currently only supported under Mac OS X 10.5 and later.
#endif

#define RK_PROBE_FIRE(probeName, ...)
#define RK_PROBE_ENABLED(probeName)                      0  // Always false
#define RK_PROBE(probeName, ...)
#define RK_PROBE_CONDITIONAL(probeName, condition, ...)

#endif // ENABLE_DTRACE_INSTRUMENTATION

#endif // _REGEXKIT_REGEXKITPRIVATEDTRACE_H_

#ifdef __cplusplus
  }  /* extern "C" */
#endif
