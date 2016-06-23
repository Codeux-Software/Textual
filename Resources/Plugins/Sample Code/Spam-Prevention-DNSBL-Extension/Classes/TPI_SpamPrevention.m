
/* Include relevant header files */
#import "TPI_SpamPrevention.h"

#include <sys/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>

/* Set INCLUDE_AUTOMATIC_LOOKUP_ROUTINE to 1 if you wish for this plugin to automatically
 check the address of each user that joins a channel. If set to 0, then the plugin only
 functions when the "dnsbl" command is invoked. */
#define INCLUDE_AUTOMATIC_LOOKUP_ROUTINE		1

@implementation TPI_SpamPreventionDNSBLController

#pragma mark -
#pragma mark Incoming Server Data

#if INCLUDE_AUTOMATIC_LOOKUP_ROUTINE == 1
- (void)didReceiveServerInput:(THOPluginDidReceiveServerInputConcreteObject *)inputObject onClient:(IRCClient *)client
{
	[self performBlockOnGlobalQueue:^{
		NSString *channelName = [inputObject messageParamaters][0];
		
		//if ([channelName isEqualIgnoringCase:@"#textual"] ||
		//	[channelName isEqualIgnoringCase:@"#textual-dev"] ||
		//	[channelName isEqualIgnoringCase:@"#textual-unregistered"])
		//{
			NSString *userAddress = [inputObject senderAddress];

			LogToConsoleDebug("Attempting to resolve address: %@", userAddress);
			
			if (userAddress) {
				NSDictionary *lookupResults = [self resolveBlacklistEntryFromAddress:userAddress];
				
				if (lookupResults) {
					NSString *userNickname = [inputObject senderNickname];
					
					[self performBlockOnMainThread:^{
						IRCChannel *destination = [client findChannel:channelName];
						
						if (destination) {
							NSString *formattedMessage = [self warningMessageInRelationToBlacklistEntry:lookupResults forNickname:userNickname inChannel:destination onClient:client];
							
							[self postWarningInRelationToBlacklistEntry:formattedMessage onClient:client];
						}
					}];
				}
			}
		//}
	}];
}

- (NSArray *)subscribedServerInputCommands
{
	return @[@"join"];
}
#endif

#pragma mark -
#pragma mark Incoming User Data

- (void)userInputCommandInvokedOnClient:(IRCClient *)client commandString:(NSString *)commandString messageString:(NSString *)messageString
{
	[self performBlockOnGlobalQueue:^{
		if ([commandString isEqualToString:@"DNSBL"]) {
			IRCChannel *selectedChannel = [mainWindow() selectedChannel];
			
			NSAssertReturn([selectedChannel isChannel]);

			for (IRCUser *user in [selectedChannel memberList]) {
				@autoreleasepool {
					NSString *userAddress = [user address];

					NSString *formattedMessage = nil;

					if (userAddress) {
						NSDictionary *lookupResults = [self resolveBlacklistEntryFromAddress:userAddress];

						if (lookupResults) {
							formattedMessage = [self warningMessageInRelationToBlacklistEntry:lookupResults forNickname:[user nickname] inChannel:selectedChannel onClient:client];
						} else {
							formattedMessage = TPILocalizedString(@"BasicLanguage[1002]", [user nickname]);
						}
					} else {
						formattedMessage = TPILocalizedString(@"BasicLanguage[1003]", [user nickname]);
					}

					[self performBlockOnMainThread:^{
						[client printDebugInformation:formattedMessage channel:selectedChannel];
					}];
				}
			}
		}
	}];
}

- (NSArray *)subscribedUserInputCommands
{
	return @[@"dnsbl"];
}

#pragma mark -
#pragma mark Private Interface

- (NSDictionary *)resolveBlacklistEntryFromAddress:(NSString *)address
{
	/* If the given address is not an IP address, then we try to resolve it. */
	NSString *_resolvedAddress = nil;
	
	if ([address isIPAddress] == NO) {
		_resolvedAddress = [self resolveHost:address];
	} else {
		_resolvedAddress = address;
	}
	
	/* Currently, this code does not support IPv6 because I did not want to
	bother implementig support for it but pull requests are welcomed. */
	if ([address isIPv6Address]) {
		return nil;
	}
	
	/* Check whether resolved address is valid. */
	if ([address isIPv4Address]) {
		/* Now that we know it is valid, we reverse all 4 sections so that
		 127.0.0.1 returns 1.0.0.127 */
		NSArray *sections = [address componentsSeparatedByString:@"."];
		
		NSString *reversedAddress = NSStringEmptyPlaceholder; // The temporary buffer
		
		for (NSInteger i = 3; i >= 0; i--) {
			if (i == 0) {
				reversedAddress = [reversedAddress stringByAppendingString:sections[i]];
			} else {
				reversedAddress = [reversedAddress stringByAppendingFormat:@"%@.", sections[i]];
			}
		}
		
		/* Now that we have an IP address to scan, then scan it. */
		/* There is no tricky science behind this. It is a DNSBL lookup so all
		 we are doing is appending the reversed address to our resolver. */
		NSDictionary *finalSearchResult = nil;

		for (NSString *entryKey in [self blacklist]) {
			@autoreleasepool {
				/* Build the search string. */
				NSDictionary *entry = [self blacklist][entryKey];

				NSString *resolver = [entry objectForKey:@"host"];
				
				NSString *combinedSearchValue = [NSString stringWithFormat:@"%@.%@", reversedAddress, resolver];
				
				/* Build the host and resolve it. */
				NSString *searchResult = [self resolveHost:combinedSearchValue];

				/* Now compare our results. */
				if (searchResult) {
					NSDictionary *possibleReasons = entry[@"returnValues"];

					if ([possibleReasons containsKey:searchResult]) {
						finalSearchResult = [@{
						  @"entryKey" : entryKey,
						  @"entryName" : entry[@"name"],
						  @"resolvedAddress" : _resolvedAddress,
						  @"returnValue" : searchResult,
						  @"returnValueReason" : possibleReasons[searchResult]
						} copy];
					}

					break; // We stop lookup on the first match
				}
			}
		}
		
		return finalSearchResult;
	}
	
	return nil;
}

- (NSString *)warningMessageInRelationToBlacklistEntry:(NSDictionary *)blacklistEntry forNickname:(NSString *)nickname inChannel:(IRCChannel *)channel onClient:(IRCClient *)client
{
	NSString *blacklistName = blacklistEntry[@"entryName"];
	NSString *resolvedAddress = blacklistEntry[@"resolvedAddress"];
	NSString *returnValueReason = blacklistEntry[@"returnValueReason"];

	NSString *formattedMessage = [NSString stringWithFormat:TPILocalizedString(@"BasicLanguage[1000]"),
								  nickname, [channel name], resolvedAddress, blacklistName, returnValueReason];
	
	return formattedMessage;
}

- (void)postWarningInRelationToBlacklistEntry:(NSString *)formattedMessage onClient:(IRCClient *)client
{
	IRCChannel *dataQuery = [client findChannelOrCreate:TPILocalizedString(@"BasicLanguage[1001]") isPrivateMessage:YES];
	
	[client print:dataQuery type:TVCLogLinePrivateMessageType nickname:nil messageBody:formattedMessage command:TVCLogLineDefaultCommandValue];
	
	[client performSelector:@selector(setUnreadState:) withObject:dataQuery];
}

- (NSString *)resolveHost:(NSString *)hostname
{
	NSString *resolvedHost = nil;

	CFArrayRef addresses;
	
	CFHostRef hostRef = CFHostCreateWithName(kCFAllocatorDefault, (CFStringRef)hostname);
	
	if (hostRef) {
		Boolean result = CFHostStartInfoResolution(hostRef, kCFHostAddresses, NULL); // pass an error instead of NULL here to find out why it failed
		
		if (result == TRUE) {
			addresses = CFHostGetAddressing(hostRef, &result);
			
			for (NSInteger i = 0; i < CFArrayGetCount(addresses); i++) {
				CFDataRef saData = (CFDataRef)CFArrayGetValueAtIndex(addresses, i);
				
				struct sockaddr_in *remoteAddr = (struct sockaddr_in *)CFDataGetBytePtr(saData);
				
				if (remoteAddr) {
					NSString *strDNS = [NSString stringWithCString:inet_ntoa(remoteAddr->sin_addr) encoding:NSASCIIStringEncoding];
					
					resolvedHost = [strDNS copy];
					
					break;
				}
			}
		}
		
		CFRelease(hostRef);
	}
	
	return resolvedHost;
}

#pragma mark -
#pragma mark Blacklist Data

- (void)pluginLoadedIntoMemory
{
	[self populateBlacklistEntries];
}

- (void)populateBlacklistEntries
{
	/* Load blacklist from property list. */
	NSString *blacklistPath = [TPIBundleFromClass() pathForResource:@"blacklist" ofType:@"plist"];
	
	NSData *rawData = [NSData dataWithContentsOfFile:blacklistPath];
	
	NSDictionary *plist = [NSPropertyListSerialization propertyListFromData:rawData
														   mutabilityOption:NSPropertyListImmutable
																	 format:NULL
														   errorDescription:NULL];
	
	if (plist == nil) {
		NSAssert(NO, @"Failed to load blacklist data.");
	}
	
	/* We are done here. */
	[self setBlacklist:plist];
}

@end
