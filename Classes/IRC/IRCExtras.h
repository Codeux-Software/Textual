// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>

@interface IRCExtras : NSObject 
{
	IRCWorld *world;
}

@property (assign) IRCWorld* world;

- (void)createConnectionAndJoinChannel:(NSString *)s chan:(NSString*)channel;
@end