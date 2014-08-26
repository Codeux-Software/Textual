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

#import "TextualApplication.h"

#import <objc/runtime.h>

@implementation NSValue (TXValueHelper)

+ (id)valueWithPrimitive:(void *)value withType:(const char *)valueType
{
	/* See runtime.h header in Objective-C for return types. */
	switch (*valueType) {
		case _C_ID: // purposely ignore these return types
		case _C_CLASS:
		{
			return (__bridge id)(value);
		}
		case _C_SHT:
		{
			return @((short)value);
		}
		case _C_USHT:
		{
			return @((unsigned short)value);
		}
		case _C_INT:
		{
			return @((int)value);
		}
		case _C_UINT:
		{
			return @((unsigned)value);
		}
		case _C_LNG:
		{
			return @((long)value);
		}
		case _C_ULNG:
		{
			return @((unsigned long)value);
		}
		case _C_LNG_LNG:
		{
			return @((long long)value);
		}
		case _C_ULNG_LNG:
		{
			return @((unsigned long long)value);
		}
		case _C_FLT:
		{
			return @(*(float *)value);
		}
		case _C_DBL:
		{
			return @(*(double *)value);
		}
		case _C_UCHR:
		{
			return @((unsigned char)value);
		}
		case _C_CHR:
		{
			if ((size_t)value == 1) {
				return @(YES);
			} else if (value == NULL) {
				return @(NO);
			} else {
				return @((char)value);
			}
		}
	}
	
	return [NSValue valueWithBytes:value objCType:valueType];
}

@end
