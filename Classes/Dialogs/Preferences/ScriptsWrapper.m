// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@implementation ScriptsWrapper

@synthesize scripts;
@synthesize world;

- (id)init
{
	if ((self = [super init])) {
		 scripts = [NSMutableArray new];
	}

	return self;
}

- (void)populateData;
{			
	NSArray *resourceFiles = [_NSFileManager() contentsOfDirectoryAtPath:[Preferences whereScriptsPath] error:NULL];
    NSMutableArray *nameParts = [[NSMutableArray alloc] init];
	for (NSString *file in resourceFiles)
    {
        nameParts = [[file componentsSeparatedByString:@"."] mutableCopy];
        NSString *script = [[nameParts stringAtIndex:0] lowercaseString];
			
        if ([scripts containsObject:script] == NO) 
        {
            [scripts safeAddObject:script];
        }
		 
	}

	for (NSString *cmd in world.bundlesForUserInput) {
		cmd = [cmd lowercaseString];
		
		if ([scripts containsObject:cmd] == NO) {
			[scripts safeAddObject:cmd];
		}
	}
	
	[scripts sortUsingSelector:@selector(compare:)];
}

- (void)dealloc
{
	[scripts drain];
	
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