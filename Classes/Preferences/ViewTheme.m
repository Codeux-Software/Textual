// Created by Satoshi Nakagawa <psychs AT limechat DOT net> <http://github.com/psychs/limechat>
// Modifications by Codeux Software <support AT codeux DOT com> <https://github.com/codeux/Textual>
// You can redistribute it and/or modify it under the new BSD license.

@interface ViewTheme (Private)
- (void)load;
@end

@implementation ViewTheme

@synthesize baseUrl;
@synthesize name;
@synthesize other;
@synthesize path;
@synthesize core_js;

- (id)init
{
	if ((self = [super init])) {
		other = [OtherTheme new];
		core_js = [FileWithContent new];
		NSString *resourcePath = [[NSBundle mainBundle] resourcePath];
		core_js.fileName = [resourcePath stringByAppendingPathComponent:@"/core.js"];
	}
	return self;
}

- (void)dealloc
{
	[name release];
	[other release];
	[core_js release];
	[path release];
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
		NSArray *kindAndName = [ViewTheme extractFileName:[Preferences themeName]];
		
		if (kindAndName) {
			NSString *kind = [kindAndName safeObjectAtIndex:0];
			NSString *fname = [kindAndName safeObjectAtIndex:1];
			
			if ([kind isEqualToString:@"resource"]) {
				path = [[Preferences whereThemesLocalPath] stringByAppendingPathComponent:fname];
			} else {
				path = [[Preferences whereThemesPath] stringByAppendingPathComponent:fname];
			}
			
			if ([TXNSFileManager() fileExistsAtPath:path] == NO) {
				if ([kind isEqualToString:@"resource"] == NO) {
					path = [[Preferences whereThemesLocalPath] stringByAppendingPathComponent:fname];
					
					if (reload) [self reload];
				}
			}
			
			if ([TXNSFileManager() fileExistsAtPath:path] == NO) {
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

+ (void)copyItemsUsingRecursionFrom:(NSString *)location 
								 to:(NSString *)dest 
					   whileForcing:(BOOL)force_reset
{
	BOOL isDirectory = NO;
	
	NSDate *oneDayAgo = [NSDate dateWithTimeIntervalSinceNow:-86400];
	
	if ([TXNSFileManager() fileExistsAtPath:dest] == NO) {
		[TXNSFileManager() createDirectoryAtPath:dest withIntermediateDirectories:YES attributes:nil error:NULL];
	}
	
	NSArray *resourceFiles = [TXNSFileManager() contentsOfDirectoryAtPath:location error:NULL];
	for (NSString *file in resourceFiles) {
		NSString *source = [location stringByAppendingPathComponent:file];
		NSString *sdest = [dest stringByAppendingPathComponent:file];
		
		[TXNSFileManager() fileExistsAtPath:source isDirectory:&isDirectory];
		[TXNSFileManager() setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:oneDayAgo, NSFileCreationDate, oneDayAgo, NSFileModificationDate, nil]
			 ofItemAtPath:source
					error:NULL];
		
		BOOL resetAttrInfo = NO;
		
		if ([TXNSFileManager() fileExistsAtPath:sdest]) {
			if (isDirectory == YES) {
				resetAttrInfo = YES;
				
				[self copyItemsUsingRecursionFrom:source to:sdest whileForcing:force_reset];
			} else {
				NSDictionary *attributes = [TXNSFileManager() attributesOfItemAtPath:sdest error:nil];
				
				if (attributes) {
					NSTimeInterval creationDate = [[attributes objectForKey:NSFileCreationDate] timeIntervalSince1970];
					NSTimeInterval modificationDate = [[attributes objectForKey:NSFileModificationDate] timeIntervalSince1970];
					
					if (creationDate == modificationDate || creationDate < 1) {
						[TXNSFileManager() removeItemAtPath:sdest error:NULL];
						
						resetAttrInfo = [TXNSFileManager() copyItemAtPath:source toPath:sdest error:NULL];
					}
				}
			}
		} else {
			if (isDirectory) {
				resetAttrInfo = YES;
				
				[self copyItemsUsingRecursionFrom:source to:sdest whileForcing:force_reset];
			} else {
				resetAttrInfo = [TXNSFileManager() copyItemAtPath:source toPath:sdest error:NULL];
			}
		}
		
		if (resetAttrInfo == YES || force_reset == YES) {
			[TXNSFileManager() setAttributes:[NSDictionary dictionaryWithObjectsAndKeys:oneDayAgo, NSFileCreationDate, oneDayAgo, NSFileModificationDate, nil]
				 ofItemAtPath:sdest 
						error:NULL];
		}
	}	
}

+ (void)createUserDirectory:(BOOL)force_reset
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	[self copyItemsUsingRecursionFrom:[Preferences whereThemesLocalPath] to:[Preferences whereThemesPath] whileForcing:force_reset];
	[self copyItemsUsingRecursionFrom:[Preferences wherePluginsLocalPath] to:[Preferences wherePluginsPath] whileForcing:force_reset];
	[self copyItemsUsingRecursionFrom:[Preferences whereScriptsLocalPath] to:[Preferences whereScriptsPath] whileForcing:force_reset];
	
	[pool release];
}

+ (NSString *)buildResourceFileName:(NSString *)name
{
	return [NSString stringWithFormat:@"resource:%@", name];
}

+ (NSString *)buildUserFileName:(NSString *)name
{
	return [NSString stringWithFormat:@"user:%@", name];
}

+ (NSArray *)extractFileName:(NSString *)source
{
	NSArray *ary = [source componentsSeparatedByString:@":"];
	if (ary.count != 2) return nil;
	return ary;
}

@end