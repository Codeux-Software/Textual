#import <Foundation/Foundation.h>

#define MODES_SIZE	52

@interface IRCModeInfo : NSObject
{
	unsigned char mode;
	BOOL plus;
	BOOL op;
	BOOL simpleMode;
	NSString* param;
}

@property (assign) unsigned char mode;
@property (assign) BOOL plus;
@property (assign) BOOL op;
@property (assign) BOOL simpleMode;
@property (retain) NSString* param;

+ (IRCModeInfo*)modeInfo;
@end

@interface IRCISupportInfo : NSObject
{
	unsigned char modes[MODES_SIZE];
	NSInteger nickLen;
	NSInteger modesCount;
}

@property (readonly) NSInteger nickLen;
@property (readonly) NSInteger modesCount;

- (void)reset;
- (void)update:(NSString*)s;
- (NSArray*)parseMode:(NSString*)s;
- (IRCModeInfo*)createMode:(NSString*)mode;
@end