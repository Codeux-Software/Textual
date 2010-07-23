#import <Cocoa/Cocoa.h>

@interface TPIUserJoinValidation : NSObject 

- (void)messageReceivedByServer:(NSObject*)client 
				 sender:(NSDictionary*)senderDict 
				message:(NSDictionary*)message;
	
- (NSArray*)pluginSupportsServerInputCommands;

@end