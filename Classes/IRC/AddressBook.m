// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation AddressBook

@synthesize cid;
@synthesize hostmask;
@synthesize entryType;
@synthesize ignorePublicMsg;
@synthesize ignorePrivateMsg;
@synthesize ignoreHighlights;
@synthesize ignoreNotices;
@synthesize ignoreCTCP;
@synthesize ignoreJPQE;
@synthesize hostmaskRegex;
@synthesize notifyJoins;
@synthesize ignorePMHighlights;

- (void)dealloc
{
	[hostmask drain];
	[hostmaskRegex drain];
	
	[super dealloc];
}

- (id)initWithDictionary:(NSDictionary *)dic
{
	if ([self init]) {
		cid = (([dic integerForKey:@"cid"]) ?: TXRandomNumber(9999));
		
		hostmask = [[dic objectForKey:@"hostmask"] retain];
		
		ignorePublicMsg		= [dic boolForKey:@"ignorePublicMsg"];
		ignorePrivateMsg	= [dic boolForKey:@"ignorePrivateMsg"];
		ignoreHighlights	= [dic boolForKey:@"ignoreHighlights"];
		ignoreNotices		= [dic boolForKey:@"ignoreNotices"];
		ignoreCTCP			= [dic boolForKey:@"ignoreCTCP"];
		ignoreJPQE			= [dic boolForKey:@"ignoreJPQE"];
		notifyJoins			= [dic boolForKey:@"notifyJoins"];
		ignorePMHighlights	= [dic boolForKey:@"ignorePMHighlights"];
		
		entryType = [dic integerForKey:@"entryType"];
		
		[self processHostMaskRegex];
	}
	
	return self;
}

- (void)processHostMaskRegex
{
	if (entryType == ADDRESS_BOOK_TRACKING_ENTRY) {
		NSString *nickname = [self trackingNickname];
		
		[hostmaskRegex drain];
		hostmaskRegex = nil;
		
		[hostmask drain];
		hostmask = nil;
		
		hostmask	  = [nickname retain];
		hostmaskRegex = [[NSString stringWithFormat:@"^%@!(.*?)@(.*?)$", nickname] retain];
	} else {
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
			
			if (NSDissimilarObjects(hostmask, nhostmask)) {
				[hostmask drain];
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
			
			[hostmaskRegex drain];
			hostmaskRegex = nil;
			
			hostmaskRegex = [[NSString stringWithFormat:@"^%@$", new_hostmask] retain];
		}
	}
}

- (NSDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setInteger:cid forKey:@"cid"];
	
	[dic setObject:hostmask			forKey:@"hostmask"];
	[dic setBool:ignorePublicMsg	forKey:@"ignorePublicMsg"];
	[dic setBool:ignorePrivateMsg	forKey:@"ignorePrivateMsg"];
	[dic setBool:ignoreHighlights	forKey:@"ignoreHighlights"];
	[dic setBool:ignorePMHighlights forKey:@"ignorePMHighlights"];
	[dic setBool:ignoreNotices		forKey:@"ignoreNotices"];
	[dic setBool:ignoreCTCP			forKey:@"ignoreCTCP"];
	[dic setBool:ignoreJPQE			forKey:@"ignoreJPQE"];
	[dic setBool:notifyJoins		forKey:@"notifyJoins"];
	[dic setInteger:entryType		forKey:@"entryType"];
	
	return dic;
}

- (BOOL)checkIgnore:(NSString *)thehost
{
	if (hostmaskRegex && thehost) {
        return [TXRegularExpression string:thehost isMatchedByRegex:hostmaskRegex withoutCase:YES];
	}
	
	return NO;
}

- (NSString *)trackingNickname
{
	return [hostmask nicknameFromHostmask];
}

@end