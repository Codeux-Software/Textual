#import "IRCExtras.h"
#import "IRCClient.h"
#import "IRCClientConfig.h"
#import "IRCWorld.h"
#import "NSStringHelper.h"

@implementation IRCExtras

@synthesize world;

- (id)init
{
	if (self = [super init]) {
	}
	return self;
}

- (void)dealloc
{
	[world release];
	[super dealloc];
}

- (void)createConnectionAndJoinChannel:(NSString *)s chan:(NSString*)channel
{	
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; 
	
	BOOL useSSL = NO;
	
	NSArray* chunks;
	NSInteger port = 6667;
	NSString* server = @"";
	NSString* password = @"";
	
	if (![s contains:@" "]) {
		if ([s contains:@":"]) {
			chunks = [s componentsSeparatedByString:@":"];
			
			server = [chunks safeObjectAtIndex:0];
			NSString *tempPort = [chunks safeObjectAtIndex:1];
			
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
				
				NSString *tempPort = [chunks safeObjectAtIndex:1];
				
				if ([tempPort hasPrefix:@"+"]) {
					tempPort = [tempPort safeSubstringFromIndex:1];
				}
				
				port = [tempPort integerValue];
				
				if ([chunks count] > 2) {
					password = [chunks safeObjectAtIndex:2];
				}
			} else {
				if ([chunks count] > 2) {
					NSString *tempPort = [chunks safeObjectAtIndex:2];
					
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
				
				NSString *tempPort = [chunks safeObjectAtIndex:1];
				
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
	
	NSMutableDictionary* nsconfig = [NSMutableDictionary dictionary];
	
	[nsconfig setObject:server forKey:@"host"];
	[nsconfig setObject:server forKey:@"name"];
	
	[nsconfig setObject:[NSNumber numberWithBool:useSSL] forKey:@"ssl"];
	[nsconfig setObject:[NSNumber numberWithInteger:port] forKey:@"port"];
	[nsconfig setObject:[Preferences defaultNickname] forKey:@"nickname"];
	[nsconfig setObject:[Preferences defaultUsername] forKey:@"username"];
	[nsconfig setObject:[Preferences defaultRealname] forKey:@"realname"];
	[nsconfig setObject:[NSNumber numberWithBool:NO] forKey:@"auto_connect"];
	[nsconfig setObject:[NSNumber numberWithLong:NSUTF8StringEncoding] forKey:@"encoding"];
	
	if ([channel length] >= 2) {
		NSMutableArray* nschannels = [NSMutableArray array];
		
		[nschannels addObject:[NSDictionary dictionaryWithObjectsAndKeys:
							   channel, @"name",
							   [NSNumber numberWithBool:YES], @"auto_join",
							   [NSNumber numberWithBool:YES], @"growl",
							   @"+sn", @"mode",
							   nil]];	
		
		[nsconfig setObject:nschannels forKey:@"channels"];
	}
	
	IRCClientConfig* c = [[[IRCClientConfig alloc] initWithDictionary:nsconfig] autorelease];

	if ([password length] >= 1) {
		c.password = password;
	}	
	
	IRCClient* u = [world createClient:c reload:YES];
	[world save];
	[u connect];
	
	c = nil;
	nsconfig = nil;
	
	[pool drain];
}

@end