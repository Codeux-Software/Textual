#import <Cocoa/Cocoa.h>

@interface PluginProtocol : NSObject

- (void)messageSentByUser:(NSObject*)client
			message:(NSString*)messageString
			command:(NSString*)commandString;

- (void)messageReceivedByServer:(NSObject*)client 
				 sender:(NSDictionary*)senderDict 
				message:(NSDictionary*)messageDict;

- (NSArray*)pluginSupportsUserInputCommands;
- (NSArray*)pluginSupportsServerInputCommands;

@end