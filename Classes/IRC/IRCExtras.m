/* ********************************************************************* 
       _____        _               _    ___ ____   ____
      |_   _|___  _| |_ _   _  __ _| |  |_ _|  _ \ / ___|
       | |/ _ \ \/ / __| | | |/ _` | |   | || |_) | |
       | |  __/>  <| |_| |_| | (_| | |   | ||  _ <| |___
       |_|\___/_/\_\\__|\__,_|\__,_|_|  |___|_| \_\\____|

 Copyright (c) 2010 — 2012 Codeux Software & respective contributors.
        Please see Contributors.pdf and Acknowledgements.pdf

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

@implementation IRCExtras

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
	
	dic[@"serverAddress"] = server;
	dic[@"connectionName"] = server;
	
	[dic setInteger:port forKey:@"serverPort"];
	
	[dic setBool:useSSL forKey:@"connectUsingSSL"];
	[dic setBool:NO		forKey:@"connectOnLaunch"];
	
	dic[@"identityNckname"] = [TPCPreferences defaultNickname];
	dic[@"identityUsername"] = [TPCPreferences defaultUsername];
	dic[@"identityRealname"] = [TPCPreferences defaultRealname];
	
	dic[@"characterEncodingDefault"] = NSNumberWithLong(NSUTF8StringEncoding);
	
	if (NSObjectIsNotEmpty(c)) {
		NSMutableArray *channels = [NSMutableArray array];
		
        if ([c contains:@","]) {
            NSArray *chunks = [c componentsSeparatedByString:@","];
            
            for (__strong NSString *cc in chunks) {
                cc = cc.trim;
                
                if ([cc isChannelName]) {
                    [channels safeAddObject:@{@"channelName": cc,
					 @"joinOnConnect": NSNumberWithBOOL(YES),
					 @"enableNotifications": NSNumberWithBOOL(YES),
TPCPreferencesMigrationAssistantVersionKey : TPCPreferencesMigrationAssistantUpgradePath}];
                }
            }
        } else {
            if ([c isChannelName]) {
                [channels safeAddObject:@{@"channelName": c,
				 @"joinOnConnect": NSNumberWithBOOL(YES),
				 @"enableNotifications": NSNumberWithBOOL(YES),
TPCPreferencesMigrationAssistantVersionKey : TPCPreferencesMigrationAssistantUpgradePath}];
            }
        }
		
		dic[@"channelList"] = channels;
	}
	
	/* Migration Assistant Dictionary Addition. */
	[dic safeSetObject:TPCPreferencesMigrationAssistantUpgradePath
				forKey:TPCPreferencesMigrationAssistantVersionKey];
	
	IRCClientConfig *cf = [[IRCClientConfig alloc] initWithDictionary:dic];
    
	if (NSObjectIsNotEmpty(password)) {
		cf.password = password;
	}	
	
	IRCClient *uf = [self.world createClient:cf reload:YES];
	
	[self.world save];
	
	[uf connect];
}

@end