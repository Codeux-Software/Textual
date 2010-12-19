// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "AddressBook.h"

@implementation AddressBook

@synthesize cid;
@synthesize hostmask;
@synthesize ignorePublicMsg;
@synthesize ignorePrivateMsg;
@synthesize ignoreHighlights;
@synthesize ignoreNotices;
@synthesize ignoreCTCP;
@synthesize ignoreDCC;
@synthesize ignoreJPQE;
@synthesize hostmaskRegex;
@synthesize notifyJoins;
@synthesize notifyWhoisJoins;
@synthesize ignorePMHighlights;

- (void)dealloc
{
	[hostmask release];
	[hostmaskRegex release];
	[super dealloc];
}

- (id)init
{
	if ((self = [super init])) {
	}
	return self;
}

- (id)initWithDictionary:(NSDictionary *)dic
{
	if ([self init]) {
		cid = TXRandomThousandNumber();
		cid = [dic intForKey:@"cid"] ?: cid;
		
		hostmask = [[dic objectForKey:@"hostmask"] retain];
		
		ignorePublicMsg = [dic boolForKey:@"ignorePublicMsg"];
		ignorePrivateMsg = [dic boolForKey:@"ignorePrivateMsg"];
		ignoreHighlights = [dic boolForKey:@"ignoreHighlights"];
		ignoreNotices = [dic boolForKey:@"ignoreNotices"];
		ignoreCTCP = [dic boolForKey:@"ignoreCTCP"];
		ignoreDCC = [dic boolForKey:@"ignoreDCC"];
		ignoreJPQE = [dic boolForKey:@"ignoreJPQE"];
		notifyJoins = [dic boolForKey:@"notifyJoins"];
		notifyWhoisJoins = [dic boolForKey:@"notifyWhoisJoins"];
		ignorePMHighlights = [dic boolForKey:@"ignorePMHighlights"];
		
		[self processHostMaskRegex];
	}
	return self;
}

- (void)processHostMaskRegex
{
	if (!hostmaskRegex) {
		NSString *nhostmask = hostmask;
		
		if (![nhostmask contains:@"@"]) {
			nhostmask = [nhostmask stringByAppendingString:@"@*"];
		} 
		
		NSRange atsrange = [nhostmask rangeOfString:@"@" options:NSBackwardsSearch];
		
		if ([nhostmask length] > 3) {
			NSString *first = [nhostmask safeSubstringToIndex:atsrange.location];
			NSString *second = [nhostmask safeSubstringFromIndex:(atsrange.location + 1)];
			
			if (first) {
				if (![first contains:@"!"]) {
					nhostmask = [NSString stringWithFormat:@"%@!*@%@", first, second];
				}
			}
		}
		
		if (hostmask != nhostmask) {
			[hostmask release];
			hostmask = [nhostmask retain];
		}
		
		NSString *new_hostmask = hostmask;
		
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@"\\" withString:@"\\\\"];
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@"{" withString:@"\\{"];
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@"}" withString:@"\\}"];
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@")" withString:@"\\)"];
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@"(" withString:@"\\("];
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@"]" withString:@"\\]"];
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@"[" withString:@"\\["];
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@"^" withString:@"\\^"];
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@"|" withString:@"\\|"];
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@"~" withString:@"\\~"];
		new_hostmask = [new_hostmask stringByReplacingOccurrencesOfString:@"*" withString:@"(.*?)"];
		
		hostmaskRegex = [[NSString stringWithFormat:@"^%@$", new_hostmask] retain];
		new_hostmask = nil;
	}
}

- (NSDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setInt:cid forKey:@"cid"];
	
	[dic setObject:hostmask forKey:@"hostmask"];
	[dic setBool:ignorePublicMsg forKey:@"ignorePublicMsg"];
	[dic setBool:ignorePrivateMsg forKey:@"ignorePrivateMsg"];
	[dic setBool:ignoreHighlights forKey:@"ignoreHighlights"];
	[dic setBool:ignorePMHighlights forKey:@"ignorePMHighlights"];
	[dic setBool:ignoreNotices forKey:@"ignoreNotices"];
	[dic setBool:ignoreCTCP forKey:@"ignoreCTCP"];
	[dic setBool:ignoreDCC forKey:@"ignoreDCC"];
	[dic setBool:ignoreJPQE forKey:@"ignoreJPQE"];
	[dic setBool:notifyJoins forKey:@"notifyJoins"];
	[dic setBool:notifyWhoisJoins forKey:@"notifyWhoisJoins"];
	
	return dic;
}

- (BOOL)checkIgnore:(NSString *)thehost
{
	if (hostmaskRegex) {
		if ([thehost isMatchedByRegex:[hostmaskRegex lowercaseString]]) {
			return YES;
		}
	}
	
	return NO;
}

- (NSString *)trackingNickname
{
	return [hostmask nicknameFromHostmask];
}

@end