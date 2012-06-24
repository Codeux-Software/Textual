// Created by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.
// Converted to ARC Support on June 09, 2012

#import "TextualApplication.h"

@implementation TDCPreferencesScriptWrapper


- (id)init
{
	if ((self = [super init])) {
        self.scripts = [NSMutableArray new];
	}
    
	return self;
}

- (void)populateData;
{
	NSArray *scriptPaths = [NSArray arrayWithObjects:
							
#ifdef TXUserScriptsFolderAvailable
							[TPCPreferences whereScriptsUnsupervisedPath],
#endif
							
							[TPCPreferences whereScriptsLocalPath],
							[TPCPreferences whereScriptsPath], nil];
	
	for (NSString *path in scriptPaths) {
		NSArray *resourceFiles = [_NSFileManager() contentsOfDirectoryAtPath:path error:NULL];
		
		if (NSObjectIsNotEmpty(resourceFiles)) {
			for (NSString *file in resourceFiles) {
				if ([file hasPrefix:@"."] || [file hasSuffix:@".rtf"]) {
					continue;
				}
				
				NSArray  *nameParts = [file componentsSeparatedByString:@"."];
				NSString *script    = [nameParts stringAtIndex:0].lowercaseString;
				
				if ([self.scripts containsObject:script] == NO) {
					[self.scripts safeAddObject:script];
				}
			}
		}
	}
    
	for (__strong NSString *cmd in self.world.bundlesForUserInput) {
		cmd = [cmd lowercaseString];
		
		if ([self.scripts containsObject:cmd] == NO) {
			[self.scripts safeAddObject:cmd];
		}
	}
	
	[self.scripts sortUsingSelector:@selector(compare:)];
}


- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
    return [self.scripts count];
}

- (id)tableView:(NSTableView *)aTableView objectValueForTableColumn:(NSTableColumn *)aTableColumn row:(NSInteger)rowIndex
{
	return [self.scripts safeObjectAtIndex:rowIndex];
}

@end