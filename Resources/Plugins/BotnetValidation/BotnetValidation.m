#import "BotnetValidation.h"
#import <RegexKit/RegexKit.h>

@implementation BotnetValidation

- (NSArray*)pluginSupportsServerInputCommands
{
	return [NSArray arrayWithObjects:@"notice", nil];
}

- (void)messageReceivedByServer:(NSObject*)client 
				 sender:(NSDictionary*)senderDict 
				message:(NSDictionary*)messageDict
{
	NSString *server = [[messageDict objectForKey:@"messageServer"] lowercaseString];
	
	if ([server hasSuffix:@"wyldryde.org"]) {
		NSString *text = [messageDict objectForKey:@"messageSequence"];
		
		// Possible connect types
		//[06/12/2010 -:- 07:45:03 AM] *** Notice -- Client connecting on port 6667: SL0RD (sidney@blk-222-69-46.eastlink.ca) [clients]
		//[06/12/2010 -:- 07:46:08 AM] *** Notice -- Client connecting at Nikon.WyldRyde.org: claude (Mibbit@ip72-218-78-142.hr.hr.cox.net)
		
		if ([text hasPrefix:@"*** Notice -- Client connecting at"]) {
			NSString *host;
			NSArray *chunks = [text componentsSeparatedByString:@" "];
			
			if ([[chunks objectAtIndex:7] isMatchedByRegex:@"^\\[(([a-zA-Z0-9]+)\\|([a-zA-Z0-9]+)\\|([a-zA-Z0-9]+))\\]$"] ||
			    [[chunks objectAtIndex:7] isMatchedByRegex:@"^([a-zA-Z0-9]+)\\|([a-zA-Z0-9]+)\\|([a-zA-Z0-9]+)\\|([a-zA-Z0-9]+)\\|([a-zA-Z0-9]+)$"]) {
				chunks = [[chunks objectAtIndex:8] componentsSeparatedByString:@"@"];
				host = [[chunks objectAtIndex:1] substringToIndex:([[chunks objectAtIndex:1] length] - 1)];				
				
				[client performSelectorOnMainThread:@selector(sendLine:) withObject:[NSString stringWithFormat:@"GLINE *@%@ 35d Clones, trojan bots, spam bots, xdcc/fserves/leech bots, zombies, and drones are prohibited. If you feel this ban is in error you may appeal it at: http://www.wyldryde.org/bans/", host] waitUntilDone:NO];		
			}
		} else if ([text hasPrefix:@"*** Notice -- Client connecting on port"]) {
			NSString *host;
			NSArray *chunks = [text componentsSeparatedByString:@" "];
			
			if ([[chunks objectAtIndex:8] isMatchedByRegex:@"^\\[(([a-zA-Z0-9]+)\\|([a-zA-Z0-9]+)\\|([a-zA-Z0-9]+))\\]$"] ||
			    [[chunks objectAtIndex:8] isMatchedByRegex:@"^([a-zA-Z0-9]+)\\|([a-zA-Z0-9]+)\\|([a-zA-Z0-9]+)\\|([a-zA-Z0-9]+)\\|([a-zA-Z0-9]+)$"]) {
				chunks = [[chunks objectAtIndex:9] componentsSeparatedByString:@"@"];
				host = [[chunks objectAtIndex:1] substringToIndex:([[chunks objectAtIndex:1] length] - 1)];				
				
				[client performSelectorOnMainThread:@selector(sendLine:) withObject:[NSString stringWithFormat:@"GLINE *@%@ 35d Clones, trojan bots, spam bots, xdcc/fserves/leech bots, zombies, and drones are prohibited. If you feel this ban is in error you may appeal it at: http://www.wyldryde.org/bans/", host] waitUntilDone:NO];
			}
		}
	}
}

@end