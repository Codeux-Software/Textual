// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "TextualApplication.h"

@implementation IRCAddressBook

- (id)initWithDictionary:(NSDictionary *)dic
{
	if ((self = [super init])) {
		self.cid = (([dic integerForKey:@"cid"]) ?: TXRandomNumber(9999));
		
		self.hostmask = dic[@"hostmask"];
		
		self.ignorePublicMsg	= [dic boolForKey:@"ignorePublicMsg"];
		self.ignorePrivateMsg	= [dic boolForKey:@"ignorePrivateMsg"];
		self.ignoreHighlights	= [dic boolForKey:@"ignoreHighlights"];
		self.ignoreNotices		= [dic boolForKey:@"ignoreNotices"];
		self.ignoreCTCP			= [dic boolForKey:@"ignoreCTCP"];
		self.ignoreJPQE			= [dic boolForKey:@"ignoreJPQE"];
		self.notifyJoins		= [dic boolForKey:@"notifyJoins"];
		self.ignorePMHighlights	= [dic boolForKey:@"ignorePMHighlights"];
		
		self.entryType = (IRCAddressBookEntryType)[dic integerForKey:@"entryType"];
		
		[self processHostMaskRegex];

		return self;
	}

	return nil;
}

- (void)processHostMaskRegex
{
	if (self.entryType == IRCAddressBookUserTrackingEntryType) {
		NSString *nickname = [self trackingNickname];
		
		self.hostmaskRegex = nil;
		self.hostmask = nil;
		
		self.hostmask	  = nickname;
		self.hostmaskRegex = [NSString stringWithFormat:@"^%@!(.*?)@(.*?)$", nickname];
	} else {
		if (NSObjectIsEmpty(self.hostmaskRegex)) {
			NSString *nhostmask = self.hostmask;
			
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
			
			if (NSDissimilarObjects(self.hostmask, nhostmask)) {
				self.hostmask = nhostmask;
			}
			
			/* There probably is an easier way to escape characters before making
			 our regular expression, but let us do it the hard way instead. More fun. */
			
			NSString *new_hostmask = self.hostmask;
			
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
			
			self.hostmaskRegex = nil;
			self.hostmaskRegex = [NSString stringWithFormat:@"^%@$", new_hostmask];
		}
	}
}

- (NSDictionary *)dictionaryValue
{
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	dic[@"hostmask"] = self.hostmask;
	
	[dic setBool:self.ignorePublicMsg		forKey:@"ignorePublicMsg"];
	[dic setBool:self.ignorePrivateMsg		forKey:@"ignorePrivateMsg"];
	[dic setBool:self.ignoreHighlights		forKey:@"ignoreHighlights"];
	[dic setBool:self.ignorePMHighlights	forKey:@"ignorePMHighlights"];
	[dic setBool:self.ignoreNotices			forKey:@"ignoreNotices"];
	[dic setBool:self.ignoreCTCP			forKey:@"ignoreCTCP"];
	[dic setBool:self.ignoreJPQE			forKey:@"ignoreJPQE"];
	[dic setBool:self.notifyJoins			forKey:@"notifyJoins"];
	
	[dic setInteger:self.entryType			forKey:@"entryType"];
	[dic setInteger:self.cid				forKey:@"cid"];
	
	return dic;
}

- (BOOL)checkIgnore:(NSString *)thehost
{
	if (self.hostmaskRegex && thehost) {
        return [TLORegularExpression string:thehost
						  isMatchedByRegex:self.hostmaskRegex
							   withoutCase:YES];
	}
	
	return NO;
}

- (NSString *)trackingNickname
{
	return [self.hostmask nicknameFromHostmask];
}

@end