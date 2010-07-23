#import <Cocoa/Cocoa.h>

@interface IRCExtras : NSObject 
{
	IRCWorld *world;
}

@property (assign) IRCWorld* world;

- (void)createConnectionAndJoinChannel:(NSString *)s chan:(NSString*)channel;
@end