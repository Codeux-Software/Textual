// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import <Cocoa/Cocoa.h>

@interface ScriptsWrapper : NSObject <NSTableViewDelegate, NSTableViewDataSource>
{
	IRCWorld *world;
	NSMutableArray *scripts;
}

@property (nonatomic, assign) IRCWorld* world;
@property (nonatomic, retain) NSMutableArray *scripts;

- (void)populateData;
@end