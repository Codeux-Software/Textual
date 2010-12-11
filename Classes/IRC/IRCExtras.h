// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>

@interface IRCExtras : NSObject 
{
	IRCWorld *world;
}

@property (nonatomic, assign) IRCWorld* world;

- (void)createConnectionAndJoinChannel:(NSString *)s chan:(NSString*)channel;
@end