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
	[name drain];
	[path drain];
	[other drain];
	[core_js drain];
	
	[super dealloc];
}

- (NSString *)name
{
	return name;
}

- (void)setName:(NSString *)value
{
	if (name != value) {
		[name drain];
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

+ (void)createDirectoryAtLocation:(NSString *)dest 
{
	if ([_NSFileManager() fileExistsAtPath:dest] == NO) {
		[_NSFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}
}

+ (void)createUserDirectory:(BOOL)force_reset
{
	[self createDirectoryAtLocation:[Preferences whereScriptsPath]];
	[self createDirectoryAtLocation:[Preferences whereThemesPath]];
	[self createDirectoryAtLocation:[Preferences wherePluginsPath]];
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