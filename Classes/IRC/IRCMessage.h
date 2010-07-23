#import <Foundation/Foundation.h>
#import "IRCPrefix.h"

@interface IRCMessage : NSObject
{
	IRCPrefix* sender;
	NSString* command;
	NSInteger numericReply;
	NSMutableArray* params;
}

@property (retain) IRCPrefix* sender;
@property (retain) NSString* command;
@property (assign) NSInteger numericReply;
@property (retain) NSMutableArray* params;

- (id)initWithLine:(NSString*)line;

- (NSString*)paramAt:(NSInteger)index;
- (NSString*)sequence;
- (NSString*)sequence:(NSInteger)index;
@end