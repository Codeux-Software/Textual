// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "ScriptsWrapper.h"

@implementation ScriptsWrapper

@synthesize scripts;
@synthesize world;

- (id)init
{
	if ((self = [super init])) {
		 if (!scripts) {
			 scripts = [NSMutableArray new];
		 }
	}
	return self;
}

- (void)populateData;
{			
	NSFileManager *fm = [NSFileManager defaultManager];
	NSArray *resourceFiles = [fm contentsOfDirectoryAtPath:[Preferences whereScriptsPath] error:NULL];
	
	for (NSString *file in resourceFiles) {
		if ([file hasSuffix:@".scpt"]) {
			NSString *script = [[file safeSubstringToIndex:([file length] - 5)] lowercaseString];
			
			if (![scripts containsObject:script]) {
				[scripts addObject:script];
			}
		}
	}

	for (NSString *cmd in world.bundlesForUserInput) {
		cmd = [cmd lowercaseString];
		
		if (![scripts containsObject:cmd]) {
			[scripts addObject:cmd];
		}
	}
	
	[scripts sortUsingSelector:@selector(compare:)];
}

- (void)dealloc
{
	[scripts release];
	[super dealloc];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [scripts count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return [scripts safeObjectAtIndex:rowIndex];
}

@end