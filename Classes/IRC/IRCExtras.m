// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation IRCExtras

@synthesize world;

- (void)createConnectionAndJoinChannel:(NSString *)s chan:(NSString *)c
{	
	BOOL useSSL = NO;
	
	NSArray *chunks;
	
	NSInteger port = 6667;
	
	NSString *server   = nil;
	NSString *password = nil;
	NSString *tempPort = nil;
	
	if ([s contains:@" "] == NO) {
		if ([s contains:@":"]) {
			chunks = [s componentsSeparatedByString:@":"];
			
			server = [chunks safeObjectAtIndex:0];
			tempPort = [chunks safeObjectAtIndex:1];
			
			if ([tempPort hasPrefix:@"+"]) {
				useSSL = YES;
				tempPort = [tempPort safeSubstringFromIndex:1];
			}
			
			port = [tempPort integerValue];
		} else {
			server = s;
		}
	} else {
		chunks = [s componentsSeparatedByString:@" "];
		
		if ([[[chunks safeObjectAtIndex:0] uppercaseString] isEqualToString:@"-SSL"]) {
			useSSL = YES;
			
			server = [chunks safeObjectAtIndex:1];
			
			if ([server contains:@":"]) {
				chunks = [server componentsSeparatedByString:@":"];
				
				tempPort = [chunks safeObjectAtIndex:1];
				
				if ([tempPort hasPrefix:@"+"]) {
					tempPort = [tempPort safeSubstringFromIndex:1];
				}
				
				port = [tempPort integerValue];
				
				if ([chunks count] > 2) {
					password = [chunks safeObjectAtIndex:2];
				}
			} else {
				if ([chunks count] > 2) {
					tempPort = [chunks safeObjectAtIndex:2];
					
					if ([tempPort hasPrefix:@"+"]) {
						tempPort = [tempPort safeSubstringFromIndex:1];
					}
					
					port = [tempPort integerValue];
				}
				
				if ([chunks count] > 3) {
					password = [chunks safeObjectAtIndex:3];
				}
			}
		} else {
			server = [chunks safeObjectAtIndex:0];
			
			if ([server contains:@":"]) {
				chunks = [server componentsSeparatedByString:@":"];
				
				tempPort = [chunks safeObjectAtIndex:1];
				
				if ([tempPort hasPrefix:@"+"]) {
					useSSL = YES;
					tempPort = [tempPort safeSubstringFromIndex:1];
				}
				
				port = [tempPort integerValue];
				
				if ([chunks count] > 1) {
					password = [chunks safeObjectAtIndex:1];
				}
			} else {
				if ([chunks count] > 1) {
					NSString *tempPort = [chunks safeObjectAtIndex:1];
					
					if ([tempPort hasPrefix:@"+"]) {
						useSSL = YES;
						tempPort = [tempPort safeSubstringFromIndex:1];
					}
					
					port = [tempPort integerValue];
				}
				
				if ([chunks count] > 2) {
					password = [chunks safeObjectAtIndex:2];
				}
			}
		}
	}
	
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setObject:server forKey:@"host"];
	[dic setObject:server forKey:@"name"];
	
	[dic setBool:useSSL forKey:@"ssl"];
	[dic setInteger:port forKey:@"port"];
	[dic setBool:NO forKey:@"auto_connect"];
	[dic setObject:[Preferences defaultNickname] forKey:@"nickname"];
	[dic setObject:[Preferences defaultUsername] forKey:@"username"];
	[dic setObject:[Preferences defaultRealname] forKey:@"realname"];
	[dic setObject:[NSNumber numberWithLong:NSUTF8StringEncoding] forKey:@"encoding"];
	
	if (NSObjectIsNotEmpty(c)) {
		NSMutableArray *channels = [NSMutableArray array];
		
		if ([c isChannelName]) {
			[channels safeAddObject:[NSDictionary dictionaryWithObjectsAndKeys:c, @"name", 
								 NSNumberWithBOOL(YES), @"auto_join", 
								 NSNumberWithBOOL(YES), @"growl", nil]];	
		}
		
		[dic setObject:channels forKey:@"channels"];
	}
	
	IRCClientConfig *cf = [[[IRCClientConfig alloc] initWithDictionary:dic] autodrain];

	if (NSObjectIsNotEmpty(password)) {
		cf.password = password;
	}	
	
	IRCClient *uf = [world createClient:cf reload:YES];
	
	[world save];
	
	[uf connect];
}

@end