#import <Cocoa/Cocoa.h>

@interface BotnetValidation : NSObject

- (void)messageReceivedByServer:(NSObject*)client 
				 sender:(NSDictionary*)senderDict 
				message:(NSDictionary*)message;

- (NSArray*)pluginSupportsServerInputCommands;

@end

@interface TextualPluginObjects : NSObject
- (void)send:(NSString*)str, ...;
@end