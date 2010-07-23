#import <Foundation/Foundation.h>

@interface IRCPrefix : NSObject
{
	NSString* raw;
	NSString* nick;
	NSString* user;
	NSString* address;
	BOOL isServer;
}

@property (retain) NSString* raw;
@property (retain) NSString* nick;
@property (retain) NSString* user;
@property (retain) NSString* address;
@property (assign) BOOL isServer;
@end