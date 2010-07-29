// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Michael Morris <mikey AT codeux DOT com> <http://github.com/mikemac11/Textual>
// You can redistribute it and/or modify it under the new BSD license.

#import "ViewTheme.h"
#import "OtherTheme.h"
#import "Preferences.h"

@interface ViewTheme (Private)
- (void)load;
@end

@implementation ViewTheme

@synthesize name;
@synthesize log;
@synthesize other;
@synthesize js;

- (id)init
{
	if (self = [super init]) {
		log = [LogTheme new];
		other = [OtherTheme new];
		js = [CustomJSFile new];
	}
	return self;
}

- (void)dealloc
{
	[name release];
	[log release];
	[other release];
	[js release];
	[super dealloc];
}

- (NSString*)name
{
	return name;
}

- (void)setName:(NSString *)value
{
	if (name != value) {
		[name release];
		name = [value retain];
	}
	
	[self load];
}

- (void)load
{
	if (name) {
		NSArray* kindAndName = [ViewTheme extractFileName:[Preferences themeName]];
		if (kindAndName) {
			NSString* kind = [kindAndName safeObjectAtIndex:0];
			NSString* fname = [kindAndName safeObjectAtIndex:1];
			NSString* fullName = nil;
			
			if ([kind isEqualToString:@"resource"]) {
				fullName = [[Preferences whereThemesLocalPath] stringByAppendingPathComponent:fname];
			} else {
				fullName = [[Preferences whereThemesPath] stringByAppendingPathComponent:fname];
			}
			
			log.fileName = [fullName stringByAppendingPathComponent:@"/design.css"];
			js.fileName = [fullName stringByAppendingPathComponent:@"/scripts.js"];
			other.fileName = [fullName stringByAppendingPathComponent:@"/userInterface.plist"];
			return;
		}
	}
	
	log.fileName = nil;
	js.fileName = nil;
	other.fileName = nil;
}

- (void)reload
{
	[log reload];
	[other reload];
	[js reload];
}

+ (void)createUserDirectory
{
	NSFileManager* fm = [NSFileManager defaultManager];
	
	BOOL isDir = NO;
	NSArray* resourceFiles;
	
	if (![fm fileExistsAtPath:[Preferences whereScriptsPath] isDirectory:&isDir]) {
		[fm createDirectoryAtPath:[Preferences whereScriptsPath] withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	resourceFiles = [fm contentsOfDirectoryAtPath:[Preferences whereScriptsLocalPath] error:NULL];
	for (NSString* file in resourceFiles) {
		NSString* source = [[Preferences whereScriptsLocalPath] stringByAppendingPathComponent:file];
		NSString* dest = [[Preferences whereScriptsPath] stringByAppendingPathComponent:file];
		
		if ([fm fileExistsAtPath:dest]) {
			//[fm removeItemAtPath:dest error:NULL];
		} else {
			[fm copyItemAtPath:source toPath:dest error:NULL];
		}
	}
	
	if (![fm fileExistsAtPath:[Preferences whereThemesPath] isDirectory:&isDir]) {
		[fm createDirectoryAtPath:[Preferences whereThemesPath] withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	resourceFiles = [fm contentsOfDirectoryAtPath:[Preferences whereThemesLocalPath] error:NULL];
	for (NSString* file in resourceFiles) {
		NSString* source = [[Preferences whereThemesLocalPath] stringByAppendingPathComponent:file];
		NSString* dest = [[Preferences whereThemesPath] stringByAppendingPathComponent:file];
		
		if ([fm fileExistsAtPath:dest]) {
			//[fm removeItemAtPath:dest error:NULL];
		} else {
			[fm copyItemAtPath:source toPath:dest error:NULL];
		}
	}
	
	if (![fm fileExistsAtPath:[Preferences wherePluginsPath] isDirectory:&isDir]) {
		[fm createDirectoryAtPath:[Preferences wherePluginsPath] withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	resourceFiles = [fm contentsOfDirectoryAtPath:[Preferences wherePluginsLocalPath] error:NULL];
	for (NSString* file in resourceFiles) {
		NSString* source = [[Preferences wherePluginsLocalPath] stringByAppendingPathComponent:file];
		NSString* dest = [[Preferences wherePluginsPath] stringByAppendingPathComponent:file];
		
		if ([fm fileExistsAtPath:dest]) {
			[fm removeItemAtPath:dest error:NULL];
		} 
		
		[fm copyItemAtPath:source toPath:dest error:NULL];
	}
}

+ (NSString*)buildResourceFileName:(NSString*)name
{
	return [NSString stringWithFormat:@"resource:%@", name];
}

+ (NSString*)buildUserFileName:(NSString*)name
{
	return [NSString stringWithFormat:@"user:%@", name];
}

+ (NSArray*)extractFileName:(NSString*)source
{
	NSArray* ary = [source componentsSeparatedByString:@":"];
	if (ary.count != 2) return nil;
	return ary;
}

@end