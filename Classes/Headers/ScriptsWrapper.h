// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface ScriptsWrapper : NSObject <NSTableViewDelegate, NSTableViewDataSource>
{
	IRCWorld *world;
	
	NSMutableArray *scripts;
}

@property (nonatomic, assign) IRCWorld *world;
@property (nonatomic, retain) NSMutableArray *scripts;

- (void)populateData;
@end