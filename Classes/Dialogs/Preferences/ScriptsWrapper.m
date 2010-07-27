// Created by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "ScriptsWrapper.h"
#import "Preferences.h"

@implementation ScriptsWrapper

- (id)init
{
	if (self = [super init]) {
		 if (!scripts) {
			 scripts = [NSMutableArray new];
			 NSFileManager *fm = [NSFileManager defaultManager];
			 
			 NSArray* resourceFiles = [fm contentsOfDirectoryAtPath:[Preferences whereScriptsPath] error:NULL];
			 for (NSString* file in resourceFiles) {
				 if ([file hasSuffix:@".scpt"]) {
					 [scripts addObject:[file safeSubstringToIndex:([file length] - 5)]];
				 }
			 }
		}	
	}
	return self;
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

@synthesize scripts;
@end