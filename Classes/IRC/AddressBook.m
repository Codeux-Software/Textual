// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation AddressBook

@synthesize cid;
@synthesize hostmask;
@synthesize ignorePublicMsg;
@synthesize ignorePrivateMsg;
@synthesize ignoreHighlights;
@synthesize ignoreNotices;
@synthesize ignoreCTCP;
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

- (id)initWithDictionary:(NSDictionary *)dic
{
	if ([self init]) {
		cid = (([dic intForKey:@"cid"]) ?: TXRandomThousandNumber());
		
		hostmask = [[dic objectForKey:@"hostmask"] retain];
		
		ignorePublicMsg = [dic boolForKey:@"ignorePublicMsg"];
		ignorePrivateMsg = [dic boolForKey:@"ignorePrivateMsg"];
		ignoreHighlights = [dic boolForKey:@"ignoreHighlights"];
		ignoreNotices = [dic boolForKey:@"ignoreNotices"];
		ignoreCTCP = [dic boolForKey:@"ignoreCTCP"];
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
	if (NSObjectIsEmpty(hostmaskRegex)) {
		NSString *nhostmask = hostmask;
		
		if ([nhostmask contains:@"@"] == NO) {
			nhostmask = [nhostmask stringByAppendingString:@"@*"];
		} 
		
		NSRange atsrange = [nhostmask rangeOfString:@"@" options:NSBackwardsSearch];
		
		if ([nhostmask length] >= 2) {
			NSString *first = [nhostmask safeSubstringToIndex:atsrange.location];
			NSString *second = [nhostmask safeSubstringFromIndex:(atsrange.location + 1)];
			
			if (NSObjectIsEmpty(first)) {
				first = @"*";
			}
			
			if ([first contains:@"!"] == NO) {
				nhostmask = [NSString stringWithFormat:@"%@!*@%@", first, second];
			}
		}
		
		if (hostmask != nhostmask) {
			[hostmask release];
			hostmask = [nhostmask retain];
		}
		
		/* There probably is an easier way to escape characters before making
		 our regular expression, but let us do it the hard way instead. More fun. */
		
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
	[dic setBool:ignoreJPQE forKey:@"ignoreJPQE"];
	[dic setBool:notifyJoins forKey:@"notifyJoins"];
	[dic setBool:notifyWhoisJoins forKey:@"notifyWhoisJoins"];
	
	return dic;
}

- (BOOL)checkIgnore:(NSString *)thehost
{
	if (hostmaskRegex && thehost) {
		return [thehost isMatchedByRegex:hostmaskRegex options:RKLCaseless inRange:NSMakeRange(0, [thehost length]) error:NULL];
	}
	
	return NO;
}

- (NSString *)trackingNickname
{
	return [hostmask nicknameFromHostmask];
}

@end