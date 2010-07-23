#import "TPIUserJoinValidation.h"

@implementation TPIUserJoinValidation

- (NSArray*)pluginSupportsServerInputCommands
{
	return [NSArray arrayWithObjects:@"join", nil];
}

- (void)messageReceivedByServer:(NSObject*)client 
				 sender:(NSDictionary*)senderDict 
				message:(NSDictionary*)messageDict
{
	NSString *server = [[messageDict objectForKey:@"messageServer"] lowercaseString];
	
	if ([server hasSuffix:@"wyldryde.org"]) {
		NSString *nickname = [[senderDict objectForKey:@"senderNickname"] lowercaseString];
		NSString *channel = [[(NSArray*)[messageDict objectForKey:@"messageParamaters"] objectAtIndex:0] lowercaseString];
	
		if ([nickname isEqualToString:@"hamburger"] && [channel isEqualToString:@"#gamerx287"]) {
			[client performSelectorOnMainThread:@selector(sendLine:) withObject:[NSString stringWithFormat:@"GLINE *@%@ 35d Your behavior is not conducive to the desired environment. If you feel this ban is in error you may appeal it at: http://www.wyldryde.org/bans/", [senderDict objectForKey:@"senderDNSMask"]] waitUntilDone:NO];		
		}
	}
}

@end