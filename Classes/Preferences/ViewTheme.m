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

+ (void)copyItemsFrom:(NSString *)location to:(NSString *)dest whileForcing:(BOOL)force_reset
{
	BOOL isDir = NO;
	
	NSDate *oneDayAgo = [NSDate dateWithTimeIntervalSinceNow:-86400];
	
	NSFileManager* fm = [NSFileManager defaultManager];
	
	if (![fm fileExistsAtPath:dest isDirectory:&isDir]) {
		[fm createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	NSArray* resourceFiles = [fm contentsOfDirectoryAtPath:location error:NULL];
	for (NSString* file in resourceFiles) {
		NSString* source = [location stringByAppendingPathComponent:file];
		NSString* sdest = [dest stringByAppendingPathComponent:file];
		
		[fm setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:oneDayAgo, NSFileCreationDate, oneDayAgo, NSFileModificationDate, nil]
			 ofItemAtPath:source
					error:NULL];
		
		BOOL resetAttrInfo = NO;
		
		if ([fm fileExistsAtPath:sdest]) {
			NSDictionary *attributes = [fm attributesOfItemAtPath:sdest error:nil];
			
			if (attributes) {
				NSTimeInterval creationDate = [[attributes objectForKey:NSFileCreationDate] timeIntervalSince1970];
				NSTimeInterval modificationDate = [[attributes objectForKey:NSFileModificationDate] timeIntervalSince1970];
				
				if (creationDate == modificationDate || creationDate < 1) {
					[fm removeItemAtPath:sdest error:NULL];
					
					resetAttrInfo = [fm copyItemAtPath:source toPath:sdest error:NULL];
				}
			}
		} else {
			resetAttrInfo = [fm copyItemAtPath:source toPath:sdest error:NULL];
		}
		
		if (resetAttrInfo == YES || force_reset == YES) {
			[fm setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:oneDayAgo, NSFileCreationDate, oneDayAgo, NSFileModificationDate, nil]
				 ofItemAtPath:sdest 
						error:NULL];
		}
	}	
}

+ (void)createUserDirectory:(BOOL)force_reset
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self copyItemsFrom:[Preferences whereThemesLocalPath] to:[Preferences whereThemesPath] whileForcing:force_reset];
	[self copyItemsFrom:[Preferences wherePluginsLocalPath] to:[Preferences wherePluginsPath] whileForcing:force_reset];
	[self copyItemsFrom:[Preferences whereScriptsLocalPath] to:[Preferences whereScriptsPath] whileForcing:force_reset];
	
	[pool release];
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