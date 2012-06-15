// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 09, 2012

@implementation IRCExtras

@synthesize world;

- (void)parseIRCProtocolURI:(NSString *)location 
{
    location = [location decodeURIFragement];
    
	NSInteger port = 6667;
	
	NSString *server  = nil;
    NSString *target  = nil;
    NSString *tempval = nil;
    
    BOOL useSSL = NO;
    
    if ([location hasPrefix:@"irc://"]) {
        location = [location safeSubstringFromIndex:6];
	} else if ([location hasPrefix:@"ircs://"]) {
		location = [location safeSubstringFromIndex:7];
		
		useSSL = YES;
	} else {
		return;
	}
	
	if ([location contains:@"/"] == NO) {
		location = [NSString stringWithFormat:@"%@/", location];
	}
	
	NSInteger slashPos = [location stringPosition:@"/"];
	
	tempval = [location safeSubstringToIndex:slashPos];
	
	/* Server Address */
	if ([tempval hasPrefix:@"["]) {
		if ([tempval contains:@"]"]) {
			NSInteger startPos = ([tempval stringPosition:@"["] + 1);
			NSInteger endPos   =  [tempval stringPosition:@"]"];
			
			NSRange servRange = NSMakeRange(startPos, (endPos - startPos));
			
			server  = [tempval safeSubstringWithRange:servRange];
			tempval = [tempval safeSubstringAfterIndex:endPos];
		} else {
			return;
		}
	} else {
		if ([tempval contains:@":"]) {
			NSInteger cutPos = [tempval stringPosition:@":"];
			
			server  = [tempval safeSubstringToIndex:cutPos];
			tempval = [tempval safeSubstringFromIndex:cutPos];
		} else {
			server  = tempval;
			tempval = nil;
		}
	}
	
	/* Server Port */
	if ([tempval hasPrefix:@":"]) {
		NSInteger chopIndex = 1;
		
		if ([tempval hasPrefix:@":+"]) {
			chopIndex = 2;
			
			useSSL = YES;
		}
		
		tempval = [tempval safeSubstringFromIndex:chopIndex];
		
		if ([TLORegularExpression string:tempval isMatchedByRegex:@"^([0-9]{1,6})$"]) {
			port = [tempval integerValue];
		}
	}
	
	tempval = [location safeSubstringAfterIndex:slashPos];
	
	if (NSObjectIsNotEmpty(tempval)) {
		if ([tempval contains:@","]) {
			NSArray         *items  = [tempval componentsSeparatedByString:@","];
			NSMutableArray  *mitems = [items mutableCopy];
			
			target = [mitems safeObjectAtIndex:0];
			
			if ([target hasPrefix:@"#"] == NO) {
				target = [NSString stringWithFormat:@"#%@", target];
			}
			
			[mitems removeObjectAtIndex:0];
			
			for (NSString *setting in mitems) {
				if ([setting isEqualNoCase:@"needssl"]) {
					useSSL = YES;
				}
			}
			
		} else {
			target = tempval;
			
			if ([target hasPrefix:@"#"] == NO) {
				target = [NSString stringWithFormat:@"#%@", target];
			}
		}
    }
    
    /* Add Server */
    if (NSObjectIsEmpty(server)) {
        return;
    }
    
    NSMutableString *servsubmit = [NSMutableString string];
    
    if (useSSL) {
        [servsubmit appendString:@"-SSL "];
    }
    
    [servsubmit appendFormat:@"%@:%d", server, port];
    
    [self createConnectionAndJoinChannel:servsubmit chan:target];
}

- (void)createConnectionAndJoinChannel:(NSString *)s chan:(NSString *)c
{	
	NSInteger port = 6667;
	
	NSString *server   = nil;
	NSString *password = nil;
    NSString *tempval  = nil;
    
    BOOL useSSL = NO;
    
    NSMutableString *base = [s mutableCopy];
    
    tempval = [base getToken];
    
    /* Secure Socket Layer */
    if ([tempval isEqualNoCase:@"-SSL"]) {
        useSSL = YES;
        
        tempval = [base getToken];
    }
    
    /* Server Address */
    if ([tempval hasPrefix:@"["]) {
        if ([tempval contains:@"]"]) {
            NSInteger startPos = ([tempval stringPosition:@"["] + 1);
            NSInteger endPos   =  [tempval stringPosition:@"]"];
            
            NSRange servRange = NSMakeRange(startPos, (endPos - startPos));
            
            server  = [tempval safeSubstringWithRange:servRange];
            tempval = [tempval safeSubstringAfterIndex:endPos];
        } else {
            return;
        }
    } else {
        if ([tempval contains:@":"]) {
            NSInteger cutPos = [tempval stringPosition:@":"];
            
            server  = [tempval safeSubstringToIndex:cutPos];
            tempval = [tempval safeSubstringFromIndex:cutPos];
        } else {
            server  = tempval;
            tempval = nil;
        }
    }
    
    /* Server Port */
    if ([tempval hasPrefix:@":"]) {
        NSInteger chopIndex = 1;
        
        if ([tempval hasPrefix:@":+"]) {
            chopIndex = 2;
            
            useSSL = YES;
        }
        
        tempval = [tempval safeSubstringFromIndex:chopIndex];
        
        if ([TLORegularExpression string:tempval isMatchedByRegex:@"^([0-9]{1,6})$"]) {
            port = [tempval integerValue];
        }
    } else {
        if (NSObjectIsNotEmpty(base)) {
            tempval = [base getToken];
            
            if ([TLORegularExpression string:tempval isMatchedByRegex:@"^(\\+?[0-9]{1,6})$"]) {
                if ([tempval hasPrefix:@"+"]) {
                    tempval = [tempval safeSubstringFromIndex:1];
                    useSSL = YES;
                }
                
                port = [tempval integerValue];
            }
        }
    }
    
    /* Server Password */
    if (NSObjectIsNotEmpty(base)) {
        tempval = [base getToken];
        
        password = tempval;
    }
    
    /* Add Server */
    if (NSObjectIsEmpty(server)) {
        return;
    }
    
	NSMutableDictionary *dic = [NSMutableDictionary dictionary];
	
	[dic setObject:server forKey:@"host"];
	[dic setObject:server forKey:@"name"];
	
	[dic setInteger:port forKey:@"port"];
	
	[dic setBool:useSSL forKey:@"ssl"];
	[dic setBool:NO		forKey:@"auto_connect"];
	
	[dic setObject:[TPCPreferences defaultNickname]			forKey:@"nickname"];
	[dic setObject:[TPCPreferences defaultUsername]			forKey:@"username"];
	[dic setObject:[TPCPreferences defaultRealname]			forKey:@"realname"];
	
	[dic setObject:NSNumberWithLong(NSUTF8StringEncoding)	forKey:@"encoding"];
	
	if (NSObjectIsNotEmpty(c)) {
		NSMutableArray *channels = [NSMutableArray array];
		
        if ([c contains:@","]) {
            NSArray *chunks = [c componentsSeparatedByString:@","];
            
            for (__strong NSString *cc in chunks) {
                cc = cc.trim;
                
                if ([cc isChannelName]) {
                    [channels safeAddObject:[NSDictionary dictionaryWithObjectsAndKeys:cc, @"name", 
                                             NSNumberWithBOOL(YES), @"auto_join", 
                                             NSNumberWithBOOL(YES), @"growl", nil]];	
                }
            }
        } else {
            if ([c isChannelName]) {
                [channels safeAddObject:[NSDictionary dictionaryWithObjectsAndKeys:c, @"name", 
                                         NSNumberWithBOOL(YES), @"auto_join", 
                                         NSNumberWithBOOL(YES), @"growl", nil]];	
            }
        }
		
		[dic setObject:channels forKey:@"channels"];
	}
	
	IRCClientConfig *cf = [[IRCClientConfig alloc] initWithDictionary:dic];
    
	if (NSObjectIsNotEmpty(password)) {
		cf.password = password;
	}	
	
	IRCClient *uf = [self.world createClient:cf reload:YES];
	
	[self.world save];
	
	[uf connect];
}

@end