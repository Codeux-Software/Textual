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
	NSArray *scriptPaths = [NSArray arrayWithObjects:
							
#ifdef _USES_APPLICATION_SCRIPTS_FOLDER
							[Preferences whereScriptsUnsupervisedPath],
#endif
							
							[Preferences whereScriptsLocalPath],
							[Preferences whereScriptsPath], nil];
	
	for (NSString *path in scriptPaths) {
		NSArray *resourceFiles = [_NSFileManager() contentsOfDirectoryAtPath:path error:NULL];
		
		if (NSObjectIsNotEmpty(resourceFiles)) {
			for (NSString *file in resourceFiles) {
				if ([file hasPrefix:@"."] || [file hasSuffix:@".rtf"]) {
					continue;
				}
				
				NSArray     *nameParts  = [file componentsSeparatedByString:@"."];
				NSString    *script     = [[nameParts stringAtIndex:0] lowercaseString];
				
				if ([scripts containsObject:script] == NO) {
					[scripts safeAddObject:script];
				}
			}
		}
	}
    
	for (__strong NSString *cmd in world.bundlesForUserInput) {
		cmd = [cmd lowercaseString];
		
		if ([scripts containsObject:cmd] == NO) {
			[scripts safeAddObject:cmd];
		}
	}
	
	[scripts sortUsingSelector:@selector(compare:)];
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