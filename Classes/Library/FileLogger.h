#import <Cocoa/Cocoa.h>

@class IRCClient;

@class IRCChannel;

@interface FileLogger : NSObject
{
	IRCClient* client;
	IRCChannel* channel;
	
	NSString* fileName;
	NSFileHandle* file;
}

@property (assign) IRCClient* client;
@property (assign) IRCChannel* channel;
@property (retain) NSString* fileName;
@property (retain) NSFileHandle* file;

- (void)open;
- (void)close;
- (void)reopenIfNeeded;

- (void)writeLine:(NSString*)s;
@end