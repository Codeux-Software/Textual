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

#import "TextualApplication.h"

#define _reservedSlotDictionaryKey			@"Reserved Information"

@implementation IRCCommandIndex

static NSDictionary *IRCCommandIndexPublicValues = nil;
static NSDictionary *IRCCommandIndexPrivateValues = nil;

+ (void)populateCommandIndex
{
	static BOOL _dataPopulated = NO;

	if (_dataPopulated == NO) {
		/* Populate public data */
		id publicValue = [TPCResourceManager loadContentsOfPropertyListInResources:@"IRCCommandIndexPublicValues"];

		if (publicValue) {
			NSMutableDictionary *mutplist = [publicValue mutableCopy];

			[mutplist removeObjectForKey:_reservedSlotDictionaryKey];

			IRCCommandIndexPublicValues = [mutplist copy];
		}

		/* Populate private data */
		id privateValue = [TPCResourceManager loadContentsOfPropertyListInResources:@"IRCCommandIndexPrivateValues"];

		if (privateValue) {
			NSMutableDictionary *mutplist = [privateValue mutableCopy];

			[mutplist removeObjectForKey:_reservedSlotDictionaryKey];

			IRCCommandIndexPrivateValues = [mutplist copy];
		}
		
		/* Only error checking we need. It either fails or succeeds. */
		if (IRCCommandIndexPrivateValues == nil) {
			NSAssert(NO, @"Unable to populate command index.");
		}
		
		if (IRCCommandIndexPublicValues == nil) {
			NSAssert(NO, @"Unable to populate command index.");
		}
	}
	
	_dataPopulated = YES;
}

+ (NSDictionary *)IRCCommandIndex:(BOOL)isPublic
{
	if (isPublic == NO) {
		return IRCCommandIndexPrivateValues;
	} else {
		return IRCCommandIndexPublicValues;
	}
}

+ (NSArray *)publicIRCCommandList
{
	NSMutableArray *index = [NSMutableArray array];
	
	BOOL inDevMode = [RZUserDefaults() boolForKey:TXDeveloperEnvironmentToken];
	
	for (NSString *indexKey in IRCCommandIndexPublicValues) {
		NSDictionary *indexInfo = IRCCommandIndexPublicValues[indexKey];

		BOOL developerOnly = [indexInfo boolForKey:@"developerModeOnly"];
		
		if (inDevMode == NO && developerOnly) {
			continue;
		}
		
		[index addObject:indexInfo[@"command"]];
	}
	
	return index;
}

+ (NSString *)IRCCommandFromIndexKey:(NSString *)key publicSearch:(BOOL)isPublic
{
	NSDictionary *searchPath = [IRCCommandIndex IRCCommandIndex:isPublic];
	
	for (NSString *indexKey in searchPath) {
		if ([indexKey isEqualIgnoringCase:key]) {
			NSDictionary *indexInfo = searchPath[indexKey];

			return indexInfo[@"command"];
		}
	}
	
	return nil;
}

NSString *IRCPrivateCommandIndex(const char *key)
{
	return [IRCCommandIndex IRCCommandFromIndexKey:@(key) publicSearch:NO];
}

NSString *IRCPublicCommandIndex(const char *key)
{
	return [IRCCommandIndex IRCCommandFromIndexKey:@(key) publicSearch:YES];
}

+ (NSInteger)indexOfIRCommand:(NSString *)command
{
	return [IRCCommandIndex indexOfIRCommand:command publicSearch:YES];
}

+ (NSInteger)indexOfIRCommand:(NSString *)command publicSearch:(BOOL)isPublic
{
	NSDictionary *searchPath = [IRCCommandIndex IRCCommandIndex:isPublic];
	
	BOOL inDevMode = [RZUserDefaults() boolForKey:TXDeveloperEnvironmentToken];
	
	for (NSString *indexKey in searchPath) {
		NSDictionary *indexInfo = searchPath[indexKey];
		
		NSString *matValue = indexInfo[@"command"];
		
		if ([matValue isEqualIgnoringCase:command]) {
			if (isPublic) {
				BOOL isDevOnly = [indexInfo boolForKey:@"developerModeOnly"];
				
				if (isDevOnly && inDevMode == NO) {
					continue;
				}
			} else {
				BOOL isStandalone = [indexInfo boolForKey:@"isStandalone"];
				
				if (isStandalone == NO) {
					continue;
				}
			}
			
			return [indexInfo integerForKey:@"indexValue"];
		}
	}
	
	return -1;
}

+ (NSInteger)colonIndexForCommand:(NSString *)command
{
	/* The command index that Textual uses is complex for anyone who
	 has never seen it before, but on the other hand, it is also very
	 convenient for storing static information about any IRC command
	 that Textual may handle. For example, the internal command list
	 keeps track of where the colon (:) should be placed for specific
	 outgoing commands. Better than guessing. */
	
	NSDictionary *searchPath = [IRCCommandIndex IRCCommandIndex:NO];
	
	for (NSString *indexKey in searchPath) {
		NSDictionary *indexInfo = searchPath[indexKey];
		
		BOOL isStandalone = [indexInfo boolForKey:@"isStandalone"];
		
		if (isStandalone) {
			NSString *matValue = indexInfo[@"command"];
			
			if ([matValue isEqualIgnoringCase:command]) {
				return [indexInfo integerForKey:@"outgoingColonIndex"];
			}
		}
	}
	
	return -1;
}

@end
