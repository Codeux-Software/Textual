// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface ViewTheme (Private)
- (void)load;
@end

@implementation ViewTheme

@synthesize baseUrl;
@synthesize core_js;
@synthesize name;
@synthesize other;
@synthesize path;

- (id)init
{
	if ((self = [super init])) {
		other = [OtherTheme new];
		
		core_js = [FileWithContent new];
		core_js.filename = [[Preferences whereResourcePath] stringByAppendingPathComponent:@"/JavaScript/API/core.js"];
	}
	
	return self;
}

- (void)dealloc
{
	[name release];
	[path release];
	[other release];
	[core_js release];
	
	[super dealloc];
}

- (NSString *)name
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

- (void)validateFilePathExistanceAndReload:(BOOL)reload
{
	if (name) {
		NSString *kind = [ViewTheme extractThemeSource:[Preferences themeName]];
		NSString *filename = [ViewTheme extractThemeName:[Preferences themeName]];
		
		if (NSObjectIsNotEmpty(kind) && NSObjectIsNotEmpty(filename)) {
			if ([kind isEqualToString:@"resource"]) {
				path = [[Preferences whereThemesLocalPath] stringByAppendingPathComponent:filename];
			} else {
				path = [[Preferences whereThemesPath] stringByAppendingPathComponent:filename];
			}
			
			if ([_NSFileManager() fileExistsAtPath:path] == NO) {
				if ([kind isEqualToString:@"resource"] == NO) {
					path = [[Preferences whereThemesLocalPath] stringByAppendingPathComponent:filename];
					
					if (reload) [self reload];
				}
			}
			
			if ([_NSFileManager() fileExistsAtPath:path] == NO) {
				NSLog(@"Error: No path to local resources.");
				exit(0);
			}
			
			self.baseUrl = [NSURL fileURLWithPath:path];
			
			other.path = path;
			
			return;
		}
	}
	
	other.path = nil;
}

- (void)load
{
	[self validateFilePathExistanceAndReload:NO];
}

- (void)reload
{
	[other reload];
}

+ (void)copyItemsUsingRecursionFrom:(NSString *)location to:(NSString *)dest whileForcing:(BOOL)force_reset
{
	BOOL isDirectory = NO;
	
	NSDate *oneDayAgo = [NSDate dateWithTimeIntervalSinceNow:-86400];
	
	if ([_NSFileManager() fileExistsAtPath:dest] == NO) {
		[_NSFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	NSArray *resourceFiles = [_NSFileManager() contentsOfDirectoryAtPath:location error:NULL];
	
	for (NSString *file in resourceFiles) {
		NSString *sdest = [dest stringByAppendingPathComponent:file];
		NSString *source = [location stringByAppendingPathComponent:file];
		
		[_NSFileManager() fileExistsAtPath:source isDirectory:&isDirectory];
		[_NSFileManager() setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:oneDayAgo, NSFileCreationDate, oneDayAgo, NSFileModificationDate, nil]
							ofItemAtPath:source
								   error:NULL];
		
		BOOL resetAttrInfo = NO;
		
		if ([_NSFileManager() fileExistsAtPath:sdest]) {
			if (isDirectory == YES) {
				resetAttrInfo = YES;
				
				[self copyItemsUsingRecursionFrom:source to:sdest whileForcing:force_reset];
			} else {
				NSDictionary *attributes = [_NSFileManager() attributesOfItemAtPath:sdest error:nil];
				
				if (attributes) {
					NSTimeInterval creationDate = [[attributes objectForKey:NSFileCreationDate] timeIntervalSince1970];
					NSTimeInterval modificationDate = [[attributes objectForKey:NSFileModificationDate] timeIntervalSince1970];
					
					if (creationDate == modificationDate || creationDate < 1) {
						[_NSFileManager() removeItemAtPath:sdest error:NULL];
						
						resetAttrInfo = [_NSFileManager() copyItemAtPath:source toPath:sdest error:NULL];
					}
				}
			}
		} else {
			if (isDirectory) {
				resetAttrInfo = YES;
				
				[self copyItemsUsingRecursionFrom:source to:sdest whileForcing:force_reset];
			} else {
				resetAttrInfo = [_NSFileManager() copyItemAtPath:source toPath:sdest error:NULL];
			}
		}
		
		if (resetAttrInfo == YES || force_reset == YES) {
			[_NSFileManager() setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:oneDayAgo, NSFileCreationDate, oneDayAgo, NSFileModificationDate, nil]
								ofItemAtPath:sdest 
									   error:NULL];
		}
	}	
}

+ (void)createUserDirectory:(BOOL)force_reset
{
	[self copyItemsUsingRecursionFrom:[Preferences whereThemesLocalPath] to:[Preferences whereThemesPath] whileForcing:force_reset];
	[self copyItemsUsingRecursionFrom:[Preferences wherePluginsLocalPath] to:[Preferences wherePluginsPath] whileForcing:force_reset];
	[self copyItemsUsingRecursionFrom:[Preferences whereScriptsLocalPath] to:[Preferences whereScriptsPath] whileForcing:force_reset];
}

+ (NSString *)buildResourceFilename:(NSString *)name
{
	return [NSString stringWithFormat:@"resource:%@", name];
}

+ (NSString *)buildUserFilename:(NSString *)name
{
	return [NSString stringWithFormat:@"user:%@", name];
}

+ (NSString *)extractThemeSource:(NSString *)source
{
	if ([source hasPrefix:@"user:"] == NO && 
		[source hasPrefix:@"resource:"] == NO) return nil;
	
	return [source safeSubstringToIndex:[source stringPosition:@":"]];
}

+ (NSString *)extractThemeName:(NSString *)source
{
	if ([source hasPrefix:@"user:"] == NO && 
		[source hasPrefix:@"resource:"] == NO) return nil;

	return [source safeSubstringAfterIndex:[source stringPosition:@":"]];	
}

@end