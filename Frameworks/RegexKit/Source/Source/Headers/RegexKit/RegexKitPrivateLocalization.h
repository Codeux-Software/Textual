//
//  RegexKitPrivateLocalization.h
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
  
#ifndef _REGEXKIT_REGEXKITPRIVATELOCALIZATION_H_
#define _REGEXKIT_REGEXKITPRIVATELOCALIZATION_H_ 1

extern NSBundle *RKFrameworkBundle; // Set in the RKRegex +load method, used by all.

#define RKLocalizedStringFromTable(string, fromTable)               [RKFrameworkBundle localizedStringForKey:string value:NULL table:fromTable]
#define RKLocalizedFormatFromTable(format, fromTable, ...)          [NSString stringWithFormat:RKLocalizedStringFromTable(format, fromTable), __VA_ARGS__]
#define RKLocalizedFormatFromTableWithArgs(format, fromTable, args) RKAutorelease([[NSString alloc] initWithFormat:RKLocalizedStringFromTable(format, fromTable) arguments:args])

#define RKLocalizedString(string)                                   RKLocalizedStringFromTable(string, NULL)
#define RKLocalizedFormat(format, ...)                              RKLocalizedFormatFromTable(format, NULL, __VA_ARGS__)
#define RKLocalizedFormatWithArgs(format, args)                     RKLocalizedFormatFromTableWithArgs(format, NULL, args)

// In RKPrivate.m
NSString *RKLocalizedStringForPCRECompileErrorCode(int errorCode) RK_ATTRIBUTES(used, visibility("hidden"));

@interface NSError (RegexKitPrivate)
+ (NSError *)rkErrorWithCode:(RKInteger)errorCode localizeDescription:(NSString *)errorStringToLocalize, ...;
+ (NSError *)rkErrorWithDomain:(NSString *)errorDomain code:(RKInteger)errorCode localizeDescription:(NSString *)errorStringToLocalize, ...;
+ (NSError *)rkErrorWithDomain:(NSString *)errorDomain code:(RKInteger)errorCode userInfo:(NSDictionary *)dict localizeDescription:(NSString *)errorStringToLocalize, ...;
@end

@interface NSException (RegexKitPrivate)
+ (NSException *)rkException:(NSString *)exceptionString localizeReason:(NSString *)reasonStringToLocalize, ...;
+ (NSException *)rkException:(NSString *)exceptionString userInfo:(NSDictionary *)infoDictionary localizeReason:(NSString *)reasonStringToLocalize, ...;
+ (NSException *)rkException:(NSString *)exceptionString for:(id)object selector:(SEL)sel localizeReason:(NSString *)reasonStringToLocalize, ...;
+ (NSException *)rkException:(NSString *)exceptionString for:(id)object selector:(SEL)sel userInfo:(NSDictionary *)infoDictionary localizeReason:(NSString *)reasonStringToLocalize, ...;
@end

#endif // _REGEXKIT_REGEXKITPRIVATELOCALIZATION_H_
    
#ifdef __cplusplus
  }  /* extern "C" */
#endif
